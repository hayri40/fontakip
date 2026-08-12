import 'package:uuid/uuid.dart';

import '../../../features/transactions/data/transaction_database.dart';
import '../../../models/debt.dart';

abstract class DebtRepository {
  Future<List<Debt>> getAll();

  Future<Debt> add({
    required String description,
    required double amount,
  });

  Future<void> delete(String id);

  factory DebtRepository() = SqlDebtRepository;
}

class SqlDebtRepository implements DebtRepository {
  static final SqlDebtRepository _instance = SqlDebtRepository._();
  final _uuid = const Uuid();

  factory SqlDebtRepository() => _instance;

  SqlDebtRepository._();

  @override
  Future<List<Debt>> getAll() async {
    final db = await TransactionDatabase.instance.database;
    final maps = await db.query(
      'debts',
      orderBy: 'created_at DESC',
    );
    return maps.map(Debt.fromMap).toList();
  }

  @override
  Future<Debt> add({
    required String description,
    required double amount,
  }) async {
    final debt = Debt(
      id: _uuid.v4(),
      description: description.trim(),
      amount: amount,
      createdAt: DateTime.now(),
    );

    final db = await TransactionDatabase.instance.database;
    await db.insert('debts', debt.toMap());
    return debt;
  }

  @override
  Future<void> delete(String id) async {
    final db = await TransactionDatabase.instance.database;
    await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
