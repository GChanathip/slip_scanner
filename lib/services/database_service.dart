import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_slip.dart';
import 'extraction_notifier.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'payment_slips.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_slips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        assetId TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        extractedText TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        recipientName TEXT,
        notes TEXT,
        category TEXT,
        senderName TEXT,
        referenceId TEXT,
        senderAccount TEXT,
        receiverAccount TEXT,
        transactionTime TEXT,
        llmProcessingStatus TEXT DEFAULT 'pending',
        ragIndexed INTEGER DEFAULT 0,
        updatedAt TEXT
      )
    ''');

    // Create index for assetId to prevent duplicates
    await db.execute('''
      CREATE INDEX idx_assetId ON payment_slips(assetId)
    ''');

    // Create index for LLM processing queue
    await db.execute('''
      CREATE INDEX idx_llm_status ON payment_slips(llmProcessingStatus)
    ''');

    // Create index for reference ID lookups
    await db.execute('''
      CREATE INDEX idx_referenceId ON payment_slips(referenceId)
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add assetId column to existing table
      await db.execute('ALTER TABLE payment_slips ADD COLUMN assetId TEXT');

      // Create index for assetId
      await db.execute('''
        CREATE INDEX idx_assetId ON payment_slips(assetId)
      ''');
    }

    if (oldVersion < 3) {
      // Add LLM extraction fields
      await db.execute('ALTER TABLE payment_slips ADD COLUMN recipientName TEXT');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN category TEXT');
      await db.execute("ALTER TABLE payment_slips ADD COLUMN llmProcessingStatus TEXT DEFAULT 'pending'");
      await db.execute('ALTER TABLE payment_slips ADD COLUMN ragIndexed INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN updatedAt TEXT');

      // Create index for LLM processing queue
      await db.execute('''
        CREATE INDEX idx_llm_status ON payment_slips(llmProcessingStatus)
      ''');
    }

    if (oldVersion < 4) {
      // Add multi-bank OCR extraction fields
      await db.execute('ALTER TABLE payment_slips ADD COLUMN senderName TEXT');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN referenceId TEXT');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN senderAccount TEXT');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN receiverAccount TEXT');
      await db.execute('ALTER TABLE payment_slips ADD COLUMN transactionTime TEXT');

      await db.execute('CREATE INDEX idx_referenceId ON payment_slips(referenceId)');
    }
  }

  static Future<int> insertPaymentSlip(PaymentSlip slip) async {
    final db = await database;
    return await db.insert('payment_slips', slip.toMap());
  }

  static Future<void> insertPaymentSlipsBatch(List<PaymentSlip> slips) async {
    if (slips.isEmpty) return;
    
    try {
      final db = await database;
      
      // OPTIMIZATION: Get all existing assetIds in a single query
      final existingAssetIds = <String>{};
      final slipsWithAssetIds = slips.where((slip) => slip.assetId != null).toList();
      
      if (slipsWithAssetIds.isNotEmpty) {
        final assetIdsToCheck = slipsWithAssetIds.map((slip) => slip.assetId!).toSet().toList();
        final placeholders = List.filled(assetIdsToCheck.length, '?').join(',');
        
        final existingResult = await db.query(
          'payment_slips',
          columns: ['assetId'],
          where: 'assetId IN ($placeholders)',
          whereArgs: assetIdsToCheck,
        );
        
        existingAssetIds.addAll(existingResult.map((row) => row['assetId'] as String));
        print('🗃️ DEBUG: Found ${existingAssetIds.length} existing assetIds out of ${assetIdsToCheck.length} to check');
      }
      
      // Use transaction for atomicity
      List<int> insertedIds = [];
      await db.transaction((txn) async {
        final batch = txn.batch();
        int insertCount = 0;
        int skipCount = 0;

        for (final slip in slips) {
          bool shouldInsert = true;

          if (slip.assetId != null && existingAssetIds.contains(slip.assetId)) {
            shouldInsert = false;
            skipCount++;
          }

          if (shouldInsert) {
            batch.insert('payment_slips', slip.toMap());
            insertCount++;
          }
        }

        // Get inserted IDs for notification
        final results = await batch.commit();
        insertedIds = results.whereType<int>().toList();
        print('🗃️ DEBUG: Batch insert completed - inserted: $insertCount, skipped: $skipCount');
      });

      // Notify extraction queue that new slips are available (event-driven)
      if (insertedIds.isNotEmpty) {
        ExtractionNotifier.instance.notifyNewSlips(insertedIds);
      }
      
    } catch (e) {
      print('❌ ERROR: Database batch insert failed: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  static Future<List<String>> getProcessedAssetIds() async {
    final db = await database;
    final result = await db.query(
      'payment_slips',
      columns: ['assetId'],
      where: 'assetId IS NOT NULL',
    );
    
    return result.map((row) => row['assetId'] as String).toList();
  }

  static Future<List<PaymentSlip>> getPaymentSlips() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'payment_slips',
        orderBy: 'date DESC',
      );
      return maps.map(PaymentSlip.fromMap).toList();
    } catch (e) {
      print('❌ ERROR: Failed to get payment slips: $e');
      return []; // Return empty list on error
    }
  }

  static Future<List<PaymentSlip>> getPaymentSlipsByMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_slips',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'date DESC',
    );
    
    return maps.map(PaymentSlip.fromMap).toList();
  }

  static Future<Map<String, double>> getMonthlyTotals() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', date) as month,
          SUM(amount) as total
        FROM payment_slips
        GROUP BY strftime('%Y-%m', date)
        ORDER BY month DESC
      ''');
      
      Map<String, double> monthlyTotals = {};
      for (var row in result) {
        monthlyTotals[row['month']] = row['total'];
      }
      return monthlyTotals;
    } catch (e) {
      print('❌ ERROR: Failed to get monthly totals: $e');
      return {}; // Return empty map on error
    }
  }

  static Future<void> deletePaymentSlip(int id) async {
    final db = await database;
    await db.delete(
      'payment_slips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ LLM Processing Queue Methods ============

  /// Get slips with a specific LLM processing status
  static Future<List<PaymentSlip>> getSlipsWithStatus(String status, {int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_slips',
      where: 'llmProcessingStatus = ?',
      whereArgs: [status],
      orderBy: 'createdAt ASC',
      limit: limit,
    );
    return maps.map(PaymentSlip.fromMap).toList();
  }

  /// Count slips with a specific status
  static Future<int> countSlipsWithStatus(String status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment_slips WHERE llmProcessingStatus = ?',
      [status],
    );
    return result.first['count'] as int;
  }

  /// Update LLM processing status
  static Future<void> updateLLMStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'payment_slips',
      {
        'llmProcessingStatus': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update extracted data from LLM
  static Future<void> updateExtractedData(
    int id, {
    String? recipientName,
    String? notes,
    String? category,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (recipientName != null) updates['recipientName'] = recipientName;
    if (notes != null) updates['notes'] = notes;
    if (category != null) updates['category'] = category;

    await db.update(
      'payment_slips',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update RAG indexed status
  static Future<void> updateRAGIndexed(int id, bool indexed) async {
    final db = await database;
    await db.update(
      'payment_slips',
      {
        'ragIndexed': indexed ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get payment slips within a date range
  static Future<List<PaymentSlip>> getPaymentSlipsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_slips',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map(PaymentSlip.fromMap).toList();
  }

  /// Reset failed slips back to pending for retry
  static Future<void> resetFailedToStatus(String newStatus) async {
    final db = await database;
    await db.update(
      'payment_slips',
      {
        'llmProcessingStatus': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'llmProcessingStatus = ?',
      whereArgs: ['failed'],
    );
  }

  /// Get slips that haven't been indexed in RAG
  static Future<List<PaymentSlip>> getUnindexedSlips({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_slips',
      where: 'ragIndexed = 0 AND llmProcessingStatus = ?',
      whereArgs: ['completed'],
      orderBy: 'createdAt ASC',
      limit: limit,
    );
    return maps.map(PaymentSlip.fromMap).toList();
  }
}