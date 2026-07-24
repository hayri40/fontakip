import '../../features/transactions/data/transaction_database.dart';

class FavoritesDatabase {
  Future<List<String>> getFavorites() async {
    final db = await TransactionDatabase.instance.database;

    final result = await db.query('favorites');

    return result
        .map((e) => e['code'] as String)
        .toList();
  }

  Future<void> addFavorite(String code) async {
    final db = await TransactionDatabase.instance.database;

    await db.insert(
      'favorites',
      {
        'code': code,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> removeFavorite(String code) async {
    final db = await TransactionDatabase.instance.database;

    await db.delete(
      'favorites',
      where: 'code = ?',
      whereArgs: [code],
    );
  }
}