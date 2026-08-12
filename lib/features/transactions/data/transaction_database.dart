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
      version: 5,
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
        await db.execute('''
          CREATE TABLE stock_favorites (
            code TEXT PRIMARY KEY,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_transactions (
            id TEXT PRIMARY KEY,
            stock_symbol TEXT NOT NULL,
            date INTEGER NOT NULL,
            type TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE debts (
            id TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_fund_code ON transactions(fund_code)',
        );
        await db.execute(
          'CREATE INDEX idx_stock_transactions_date ON stock_transactions(date DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_stock_transactions_symbol ON stock_transactions(stock_symbol)',
        );
        await db.execute(
          'CREATE INDEX idx_debts_created_at ON debts(created_at DESC)',
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

        if (oldVersion < 3) {
          await db.execute('''
      CREATE TABLE stock_favorites (
        code TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
      CREATE TABLE stock_transactions (
        id TEXT PRIMARY KEY,
        stock_symbol TEXT NOT NULL,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
          await db.execute(
            'CREATE INDEX idx_stock_transactions_date ON stock_transactions(date DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_stock_transactions_symbol ON stock_transactions(stock_symbol)',
          );
        }

        if (oldVersion < 5) {
          await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
          await db.execute(
            'CREATE INDEX idx_debts_created_at ON debts(created_at DESC)',
          );
        }
      },
    );
  }
}
