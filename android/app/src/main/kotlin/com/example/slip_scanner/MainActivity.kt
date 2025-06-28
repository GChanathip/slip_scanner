package com.example.slip_scanner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.provider.MediaStore
import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.googlecode.tesseract.android.TessBaseAPI
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors
import java.util.regex.Pattern
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val VISION_CHANNEL = "com.example.slip_scanner/vision"
    private val PROGRESS_CHANNEL = "com.example.slip_scanner/progress"
    private var tessBaseApi: TessBaseAPI? = null
    private var scanningCancelled = false
    private var progressHandler: Handler? = null
    private var currentProgress: Map<String, Any> = emptyMap()
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VISION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAllPhotos" -> scanAllPhotos(result)
                "cancelScanning" -> cancelScanning(result)
                "getProcessedPhotoIds" -> getProcessedPhotoIds(result)
                "scanPaymentSlip" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        scanPaymentSlip(imagePath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image path is required", null)
                    }
                }
                "deleteSlipImage" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        deleteSlipImage(imagePath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image path is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        initializeTesseract()
    }

    private fun initializeTesseract() {
        executor.execute {
            try {
                val dataPath = File(filesDir, "tessdata")
                if (!dataPath.exists()) {
                    dataPath.mkdirs()
                }

                // Copy language files from assets to internal storage
                copyAssetToInternal("tessdata/tha.traineddata", File(dataPath, "tha.traineddata"))
                copyAssetToInternal("tessdata/eng.traineddata", File(dataPath, "eng.traineddata"))

                tessBaseApi = TessBaseAPI().apply {
                    if (!init(filesDir.absolutePath, "tha+eng")) {
                        Log.e("MainActivity", "Failed to initialize Tesseract")
                        recycle()
                        return@execute
                    }
                    setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
                }
                
                Log.d("MainActivity", "Tesseract initialized successfully with Thai+English")
            } catch (e: Exception) {
                Log.e("MainActivity", "Failed to initialize Tesseract", e)
            }
        }
    }

    private fun copyAssetToInternal(assetPath: String, destFile: File) {
        if (destFile.exists()) return // File already exists
        
        try {
            assets.open(assetPath).use { inputStream ->
                FileOutputStream(destFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            Log.d("MainActivity", "Copied $assetPath to ${destFile.absolutePath}")
        } catch (e: IOException) {
            Log.e("MainActivity", "Failed to copy asset $assetPath", e)
        }
    }

    private fun scanAllPhotos(result: MethodChannel.Result) {
        scanningCancelled = false
        
        executor.execute {
            try {
                val images = getAllImages()
                val totalCount = images.size
                var processedCount = 0
                var slipsFound = 0
                val scannedSlips = mutableListOf<Map<String, Any>>()

                // Initialize progress tracking
                currentProgress = mapOf(
                    "total" to totalCount,
                    "processed" to 0,
                    "slipsFound" to 0,
                    "isComplete" to false
                )

                // Start progress timer
                startProgressTimer()

                // Process photos in batches
                val batchSize = 20
                for (batchStart in 0 until totalCount step batchSize) {
                    if (scanningCancelled) break

                    val batchEnd = minOf(batchStart + batchSize, totalCount)
                    val batchSlips = mutableListOf<Map<String, Any>>()

                    for (i in batchStart until batchEnd) {
                        if (scanningCancelled) break

                        val imageInfo = images[i]
                        val bitmap = loadImageFromUri(imageInfo.uri)
                        
                        if (bitmap != null) {
                            val slipData = processImageForPaymentSlip(bitmap, imageInfo.id)
                            if (slipData != null) {
                                batchSlips.add(slipData)
                            }
                        }

                        processedCount++
                        
                        // Update progress immediately
                        currentProgress = mapOf(
                            "total" to totalCount,
                            "processed" to processedCount,
                            "slipsFound" to slipsFound + batchSlips.size,
                            "isComplete" to false
                        )
                        sendProgressUpdate()
                        
                        Log.d("MainActivity", "Processed photo $processedCount/$totalCount, batch slips: ${batchSlips.size}")
                    }

                    slipsFound += batchSlips.size
                    scannedSlips.addAll(batchSlips)

                    // Small delay to prevent overwhelming the system
                    Thread.sleep(50)
                }

                // Complete scanning
                currentProgress = mapOf(
                    "total" to totalCount,
                    "processed" to processedCount,
                    "slipsFound" to slipsFound,
                    "isComplete" to true
                )

                Handler(Looper.getMainLooper()).post {
                    stopProgressTimer()
                    
                    if (scanningCancelled) {
                        result.error("CANCELLED", "Scanning was cancelled", null)
                    } else {
                        result.success(mapOf(
                            "total" to totalCount,
                            "processed" to processedCount,
                            "slipsFound" to slipsFound,
                            "slips" to scannedSlips
                        ))
                    }
                }

            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("SCAN_ERROR", e.message, null)
                }
            }
        }
    }

    private fun scanPaymentSlip(imagePath: String, result: MethodChannel.Result) {
        executor.execute {
            try {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap == null) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("IMAGE_ERROR", "Could not load image from path", null)
                    }
                    return@execute
                }

                val extractedText = performOCR(bitmap)
                val amount = extractAmountFromText(extractedText)
                val date = extractDateFromText(extractedText)

                val responseData = mapOf(
                    "text" to extractedText,
                    "amount" to (amount ?: 0.0),
                    "date" to (date ?: ""),
                    "imagePath" to imagePath
                )

                Handler(Looper.getMainLooper()).post {
                    result.success(responseData)
                }

            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("OCR_ERROR", e.message, null)
                }
            }
        }
    }

    private fun cancelScanning(result: MethodChannel.Result) {
        scanningCancelled = true
        stopProgressTimer()
        result.success(true)
    }

    private fun getProcessedPhotoIds(result: MethodChannel.Result) {
        // Return empty array for now
        result.success(emptyList<String>())
    }

    private fun deleteSlipImage(imagePath: String, result: MethodChannel.Result) {
        try {
            val file = File(imagePath)
            if (file.exists()) {
                file.delete()
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    private fun startProgressTimer() {
        progressHandler = Handler(Looper.getMainLooper())
        val progressRunnable = object : Runnable {
            override fun run() {
                sendProgressUpdate()
                progressHandler?.postDelayed(this, 500) // Update every 500ms
            }
        }
        progressHandler?.post(progressRunnable)
    }

    private fun stopProgressTimer() {
        progressHandler?.removeCallbacksAndMessages(null)
        progressHandler = null
        sendProgressUpdate() // Send final update
    }

    private fun sendProgressUpdate() {
        Handler(Looper.getMainLooper()).post {
            val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, PROGRESS_CHANNEL)
            Log.d("MainActivity", "Sending progress update: $currentProgress")
            channel.invokeMethod("onProgress", currentProgress)
        }
    }

    private data class ImageInfo(val id: String, val uri: Uri)

    private fun getAllImages(): List<ImageInfo> {
        val images = mutableListOf<ImageInfo>()
        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATA
        )
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)

            while (cursor.moveToNext()) {
                val id = cursor.getString(idColumn)
                val data = cursor.getString(dataColumn)
                val imageUri = Uri.withAppendedPath(uri, id)
                images.add(ImageInfo(id, imageUri))
            }
        }

        return images
    }

    private fun loadImageFromUri(uri: Uri): Bitmap? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val options = BitmapFactory.Options().apply {
                inSampleSize = 2 // Reduce image size for faster processing
            }
            BitmapFactory.decodeStream(inputStream, null, options)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to load image from URI: $uri", e)
            null
        }
    }

    private fun processImageForPaymentSlip(bitmap: Bitmap, assetId: String): Map<String, Any>? {
        Log.d("MainActivity", "Processing image for payment slip with assetId: $assetId")
        
        val extractedText = performOCR(bitmap)
        val amount = extractAmountFromText(extractedText)
        val date = extractDateFromText(extractedText)

        Log.d("MainActivity", "OCR Result - Amount: $amount, Date: $date")
        Log.d("MainActivity", "Full extracted text: $extractedText")

        // Only return if we found an amount (indicating this might be a payment slip)
        return if (amount != null && amount > 0) {
            mapOf(
                "text" to extractedText,
                "amount" to amount,
                "date" to (date ?: ""),
                "assetId" to assetId,
                "createdAt" to SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())
            )
        } else {
            null
        }
    }

    private fun performOCR(bitmap: Bitmap): String {
        return try {
            tessBaseApi?.setImage(bitmap)
            tessBaseApi?.utF8Text ?: ""
        } catch (e: Exception) {
            Log.e("MainActivity", "OCR failed", e)
            ""
        }
    }

    private fun extractAmountFromText(text: String): Double? {
        Log.d("MainActivity", "Extracting amount from text: $text")

        // Thai banking patterns - PRIORITIZED ORDER (most specific first)
        val thaiAmountPatterns = listOf(
            // 1. SCB format: "จำนวนเงิน 1,234.56" (with comma separators)
            Regex("จำนวนเงิน\\s*(\\d{1,3}(?:,\\d{3})*\\.\\d{2})"),
            
            // 2. KBank format: "จำนวน: 1,234.56 บาท" (with comma separators)
            Regex("จำนวน:\\s*(\\d{1,3}(?:,\\d{3})*\\.\\d{2})\\s*บาท"),
            
            // 3. General format: "จำนวน 1,234.56 บาท" (with comma separators)
            Regex("จำนวน\\s+(\\d{1,3}(?:,\\d{3})*\\.\\d{2})\\s*บาท"),
            
            // 4. Simple format: "1,234.56 บาท" (with comma separators)
            Regex("(\\d{1,3}(?:,\\d{3})*\\.\\d{2})\\s*บาท"),
            
            // 5. Any Thai banking context (fallback with comma separators)
            Regex("(?:จำนวน|amount|เงิน).*?(\\d{1,3}(?:,\\d{3})*\\.\\d{2})"),
            
            // 6. Decimal numbers with proper comma formatting
            Regex("\\b(\\d{1,3}(?:,\\d{3})*\\.\\d{2})\\b"),
            
            // 7. Simple decimal numbers (no commas, under 1000)
            Regex("\\b([1-9]\\d{1,2}\\.\\d{2})\\b"),
            
            // 8. Specific patterns for common amounts
            Regex("\\b(70\\.00)\\b"),
            Regex("\\b(520\\.00)\\b"),
            Regex("\\b(1,000\\.00)\\b"),
            Regex("\\b(10,000\\.00)\\b"),
            Regex("\\b(100,000\\.00)\\b"),
            Regex("\\b(1,000,000\\.00)\\b")
        )

        for ((index, pattern) in thaiAmountPatterns.withIndex()) {
            Log.d("MainActivity", "Trying pattern ${index + 1}: $pattern")
            
            val matchResult = pattern.find(text)
            if (matchResult != null) {
                val matchedText = matchResult.value
                Log.d("MainActivity", "Pattern ${index + 1} matched: $matchedText")
                
                // Extract just the number part (supports comma separators)
                val numberPattern = Regex("(\\d{1,3}(?:,\\d{3})*\\.\\d{2})")
                val numberMatch = numberPattern.find(matchedText)
                if (numberMatch != null) {
                    val amountString = numberMatch.value
                        .replace(",", "")  // Remove commas: "1,000.00" → "1000.00"
                        .replace(" ", "")  // Remove spaces
                    
                    Log.d("MainActivity", "Extracted amount string: $amountString (after comma removal)")
                    
                    val amount = amountString.toDoubleOrNull()
                    if (amount != null) {
                        Log.d("MainActivity", "Successfully extracted amount: $amount")
                        return amount
                    } else {
                        Log.d("MainActivity", "Failed to convert '$amountString' to Double")
                    }
                } else {
                    Log.d("MainActivity", "No number found in matched text: $matchedText")
                }
            }
        }

        Log.d("MainActivity", "No amount found in text")
        return null
    }

    private fun extractDateFromText(text: String): String? {
        Log.d("MainActivity", "Extracting date from text: $text")

        // Thai date patterns with Buddhist calendar
        val thaiDatePatterns = listOf(
            Regex("(\\d{1,2})\\s*มิ\\.ย\\.\\s*(\\d{2,4})"), // June
            Regex("(\\d{1,2})\\s*ม\\.ค\\.\\s*(\\d{2,4})"), // January
            Regex("(\\d{1,2})\\s*ก\\.พ\\.\\s*(\\d{2,4})"), // February
            Regex("(\\d{1,2})\\s*มี\\.ค\\.\\s*(\\d{2,4})"), // March
            Regex("(\\d{1,2})\\s*เม\\.ย\\.\\s*(\\d{2,4})"), // April
            Regex("(\\d{1,2})\\s*พ\\.ค\\.\\s*(\\d{2,4})"), // May
            Regex("(\\d{1,2})\\s*ก\\.ค\\.\\s*(\\d{2,4})"), // July
            Regex("(\\d{1,2})\\s*ส\\.ค\\.\\s*(\\d{2,4})"), // August
            Regex("(\\d{1,2})\\s*ก\\.ย\\.\\s*(\\d{2,4})"), // September
            Regex("(\\d{1,2})\\s*ต\\.ค\\.\\s*(\\d{2,4})"), // October
            Regex("(\\d{1,2})\\s*พ\\.ย\\.\\s*(\\d{2,4})"), // November
            Regex("(\\d{1,2})\\s*ธ\\.ค\\.\\s*(\\d{2,4})"), // December
            // International formats
            Regex("\\d{1,2}/\\d{1,2}/\\d{4}"),
            Regex("\\d{1,2}-\\d{1,2}-\\d{4}"),
            Regex("\\d{4}/\\d{1,2}/\\d{1,2}"),
            Regex("\\d{4}-\\d{1,2}-\\d{1,2}")
        )

        for ((index, pattern) in thaiDatePatterns.withIndex()) {
            val matchResult = pattern.find(text)
            if (matchResult != null) {
                val dateString = matchResult.value
                Log.d("MainActivity", "Found date with pattern ${index + 1}: $dateString")
                
                // Convert Buddhist calendar to Gregorian if needed
                if (containsBuddhistYear(dateString)) {
                    val convertedDate = convertBuddhistToGregorian(dateString)
                    Log.d("MainActivity", "Converted Buddhist date '$dateString' to '$convertedDate'")
                    return convertedDate
                }
                
                Log.d("MainActivity", "Using date as-is: $dateString")
                return dateString
            }
        }

        Log.d("MainActivity", "No date found in text")
        return null
    }

    private fun containsBuddhistYear(dateString: String): Boolean {
        // Check for Buddhist Era years (typically 2500+ or 2-digit years in Thai context)
        val buddhistYearPattern = Regex("25\\d{2}|6[0-9]|7[0-9]")
        return buddhistYearPattern.containsMatchIn(dateString)
    }

    private fun convertBuddhistToGregorian(dateString: String): String {
        val monthMap = mapOf(
            "ม.ค." to "01", "ก.พ." to "02", "มี.ค." to "03", "เม.ย." to "04",
            "พ.ค." to "05", "มิ.ย." to "06", "ก.ค." to "07", "ส.ค." to "08",
            "ก.ย." to "09", "ต.ค." to "10", "พ.ย." to "11", "ธ.ค." to "12"
        )

        var result = dateString

        // Convert Thai month abbreviations to numbers
        for ((thaiMonth, monthNum) in monthMap) {
            result = result.replace(thaiMonth, "/$monthNum/")
        }

        // Convert Buddhist year to Gregorian (subtract 543 years)
        // Handle 4-digit Buddhist years (2500-2600 range)
        val fourDigitBuddhistPattern = Regex("(25\\d{2})")
        val fourDigitMatch = fourDigitBuddhistPattern.find(result)
        if (fourDigitMatch != null) {
            val buddhistYear = fourDigitMatch.value.toInt()
            val gregorianYear = buddhistYear - 543
            result = result.replace(fourDigitMatch.value, gregorianYear.toString())
        }

        // Handle 2-digit Buddhist years (60-79 representing 2560-2579 BE)
        val twoDigitBuddhistPattern = Regex("\\b([6-7]\\d)\\b")
        val twoDigitMatch = twoDigitBuddhistPattern.find(result)
        if (twoDigitMatch != null) {
            val shortYear = twoDigitMatch.value.toInt()
            val fullBuddhistYear = 2500 + shortYear
            val gregorianYear = fullBuddhistYear - 543
            result = result.replace(twoDigitMatch.value, gregorianYear.toString())
        }

        // Clean up extra spaces and format
        result = result.replace(Regex("\\s+"), "")

        return result
    }

    override fun onDestroy() {
        super.onDestroy()
        tessBaseApi?.recycle()
    }
}