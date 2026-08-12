import 'package:uuid/uuid.dart';

import '../models/stock_transaction.dart';
import '../models/transaction_type.dart';
import 'transaction_database.dart';

class StockTransactionRepository {
  static final StockTransactionRepository _instance =
      StockTransactionRepository._();
  final _uuid = const Uuid();

  factory StockTransactionRepository() => _instance;

  StockTransactionRepository._();

  Future<List<StockTransaction>> getAll() async {
    final db = await TransactionDatabase.instance.database;
    final maps = await db.query(
      'stock_transactions',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(StockTransaction.fromMap).toList();
  }

  Future<StockTransaction?> getById(String id) async {
    final db = await TransactionDatabase.instance.database;
    final maps = await db.query(
      'stock_transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return StockTransaction.fromMap(maps.first);
  }

  Future<StockTransaction> add({
    required String stockSymbol,
    required DateTime date,
    required TransactionType type,
    required double quantity,
    required double unitPrice,
  }) async {
    final transaction = StockTransaction(
      id: _uuid.v4(),
      stockSymbol: stockSymbol.toUpperCase(),
      date: date,
      type: type,
      quantity: quantity,
      unitPrice: unitPrice,
      createdAt: DateTime.now(),
    );

    final db = await TransactionDatabase.instance.database;
    await db.insert('stock_transactions', transaction.toMap());
    return transaction;
  }

  Future<void> delete(String id) async {
    final db = await TransactionDatabase.instance.database;
    await db.delete(
      'stock_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
