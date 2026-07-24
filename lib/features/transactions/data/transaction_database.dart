import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TransactionDatabase {
  static final TransactionDatabase instance = TransactionDatabase._();
  static Database? _database;

  TransactionDatabase._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fontakip_transactions.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            fund_code TEXT NOT NULL,
            date INTEGER NOT NULL,
            type TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            code TEXT PRIMARY KEY,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_fund_code ON transactions(fund_code)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE favorites (
              code TEXT PRIMARY KEY,
              created_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }
}
