import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_slip.dart';

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
      version: 2,
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
        createdAt TEXT NOT NULL
      )
    ''');
    
    // Create index for assetId to prevent duplicates
    await db.execute('''
      CREATE INDEX idx_assetId ON payment_slips(assetId)
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
        
        await batch.commit(noResult: true);
        print('🗃️ DEBUG: Batch insert completed - inserted: $insertCount, skipped: $skipCount');
      });
      
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
      return List.generate(maps.length, (i) {
        return PaymentSlip.fromMap(maps[i]);
      });
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
    
    return List.generate(maps.length, (i) {
      return PaymentSlip.fromMap(maps[i]);
    });
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
}