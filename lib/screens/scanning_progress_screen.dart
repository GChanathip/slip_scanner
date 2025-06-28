import 'package:flutter/material.dart';
import 'dart:async';
import '../services/platform_service.dart';
import '../services/database_service.dart';
import '../models/payment_slip.dart';

class ScanningProgressScreen extends StatefulWidget {
  const ScanningProgressScreen({super.key});

  @override
  State<ScanningProgressScreen> createState() => _ScanningProgressScreenState();
}

class _ScanningProgressScreenState extends State<ScanningProgressScreen> {
  late StreamSubscription _progressSubscription;
  bool _isScanning = true;
  int _totalPhotos = 0;
  int _processedPhotos = 0;
  int _slipsFound = 0;
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize progress listening BEFORE starting scanning
    _listenToProgress();
    // Small delay to ensure progress channel is set up
    Future.delayed(const Duration(milliseconds: 100), () {
      _startScanning();
    });
  }

  @override
  void dispose() {
    _progressSubscription.cancel();
    super.dispose();
  }

  void _startScanning() async {
    try {
      final result = await PlatformService.scanAllPhotos();
      
      // Always process the final results when scanAllPhotos completes
      await _processScanResults(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isScanning = false;
        });
      }
    }
  }

  void _listenToProgress() {
    _progressSubscription = PlatformService.getProgressStream().listen(
      (progress) {
        print('📊 DEBUG Flutter UI: Progress listener received: $progress');
        if (mounted) {
          setState(() {
            _totalPhotos = progress['total'] ?? 0;
            _processedPhotos = progress['processed'] ?? 0;
            _slipsFound = progress['slipsFound'] ?? 0;
            _isComplete = progress['isComplete'] ?? false;
            print('📊 DEBUG Flutter UI: Updated state - $_processedPhotos/$_totalPhotos, slips: $_slipsFound');
          });
        } else {
          print('📊 DEBUG Flutter UI: Widget not mounted, skipping update');
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isScanning = false;
          });
        }
      },
    );
  }

  Future<void> _processScanResults(Map<String, dynamic> result) async {
    try {
      final slips = result['slips'] as List<dynamic>;
      print('🔍 DEBUG Flutter: Processing ${slips.length} slips from iOS');
      
      final paymentSlips = slips.map((slip) {
        final slipData = Map<String, dynamic>.from(slip);
        
        print('🔍 DEBUG Flutter: Raw slip data: $slipData');
        print('🔍 DEBUG Flutter: Amount from iOS: ${slipData['amount']} (type: ${slipData['amount'].runtimeType})');
        print('🔍 DEBUG Flutter: Date from iOS: ${slipData['date']}');
        print('🔍 DEBUG Flutter: Text from iOS: ${slipData['text']}');
        
        DateTime slipDate = DateTime.now();
        if (slipData['date'] != null && slipData['date'].toString().isNotEmpty) {
          slipDate = _parseThaiDate(slipData['date']) ?? DateTime.now();
          print('🔍 DEBUG Flutter: Parsed date: $slipDate');
        }
        
        double amount = 0.0;
        if (slipData['amount'] != null) {
          if (slipData['amount'] is int) {
            amount = (slipData['amount'] as int).toDouble();
          } else if (slipData['amount'] is double) {
            amount = slipData['amount'] as double;
          } else {
            // Try to parse as string
            amount = double.tryParse(slipData['amount'].toString()) ?? 0.0;
          }
        }
        
        print('🔍 DEBUG Flutter: Final amount: $amount');
        
        return PaymentSlip(
          imagePath: slipData['assetId'] ?? '',
          assetId: slipData['assetId'],
          amount: amount,
          date: slipDate,
          extractedText: slipData['text'] ?? '',
          createdAt: DateTime.now(),
        );
      }).toList();

      // Save to database in batch
      await DatabaseService.insertPaymentSlipsBatch(paymentSlips);
      
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        
        // Show completion dialog and navigate back
        _showCompletionDialog(result['processed'], result['slipsFound']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save results: $e';
          _isScanning = false;
        });
      }
    }
  }

  DateTime? _parseThaiDate(String dateStr) {
    try {
      // Handle already converted dates (from iOS helper)
      if (dateStr.contains('/')) {
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          // Check if it's already in DD/MM/YYYY format from iOS conversion
          if (parts[2].length == 4) {
            return DateTime(
              int.parse(parts[2]), // Year
              int.parse(parts[1]), // Month
              int.parse(parts[0]), // Day
            );
          }
        }
      }
      
      // Handle hyphen-separated dates
      if (dateStr.contains('-')) {
        List<String> parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            // DD-MM-YYYY
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      }
    } catch (e) {
      // If parsing fails, return null to use current date
    }
    
    return null;
  }

  void _showCompletionDialog(int processed, int found) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Scanning Complete'),
        content: Text(
          'Processed $processed photos and found $found payment slips.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to home with refresh signal
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelScanning() async {
    try {
      await PlatformService.cancelScanning();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scanning Error'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Scanning Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progress = _totalPhotos > 0 ? _processedPhotos / _totalPhotos : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning Photos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isScanning ? _cancelScanning : () => Navigator.of(context).pop(false),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress circle
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: _isScanning ? progress : 1.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(_processedPhotos / (_totalPhotos == 0 ? 1 : _totalPhotos) * 100).toInt()}%',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isScanning)
                            Text(
                              'Scanning',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status text
              Text(
                _isScanning 
                    ? 'Scanning your photos for payment slips...'
                    : 'Processing results...',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Progress stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Photos Processed:'),
                          Text(
                            '$_processedPhotos / $_totalPhotos',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Slips Found:'),
                          Text(
                            '$_slipsFound',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Cancel button
              if (_isScanning)
                OutlinedButton(
                  onPressed: _cancelScanning,
                  child: const Text('Cancel Scanning'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}