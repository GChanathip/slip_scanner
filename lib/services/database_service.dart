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
    final db = await database;
    final batch = db.batch();
    
    for (final slip in slips) {
      // Check if this assetId already exists
      if (slip.assetId != null) {
        final existing = await db.query(
          'payment_slips',
          where: 'assetId = ?',
          whereArgs: [slip.assetId],
          limit: 1,
        );
        
        if (existing.isEmpty) {
          batch.insert('payment_slips', slip.toMap());
        }
      } else {
        batch.insert('payment_slips', slip.toMap());
      }
    }
    
    await batch.commit(noResult: true);
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
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_slips',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return PaymentSlip.fromMap(maps[i]);
    });
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