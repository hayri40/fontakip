import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'transaction_database.dart';

class TransactionRepository {
  static final TransactionRepository _instance = TransactionRepository._();
  final _uuid = const Uuid();

  factory TransactionRepository() => _instance;

  TransactionRepository._();

  Future<List<Transaction>> getAll() async {
    final db = await TransactionDatabase.instance.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(Transaction.fromMap).toList();
  }

  Future<Transaction?> getById(String id) async {
    final db = await TransactionDatabase.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<Transaction> add({
    required String fundCode,
    required DateTime date,
    required TransactionType type,
    required double quantity,
    required double unitPrice,
  }) async {
    final transaction = Transaction(
      id: _uuid.v4(),
      fundCode: fundCode.toUpperCase(),
      date: date,
      type: type,
      quantity: quantity,
      unitPrice: unitPrice,
      createdAt: DateTime.now(),
    );

    final db = await TransactionDatabase.instance.database;
    await db.insert('transactions', transaction.toMap());
    return transaction;
  }

  Future<void> delete(String id) async {
    final db = await TransactionDatabase.instance.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
