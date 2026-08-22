import '../core/database/favorites_database.dart';

class FavoritesManager {
  static final FavoritesManager _instance =
  FavoritesManager._internal();

  final Set<String> _favorites = {};
  final _db = FavoritesDatabase();

  factory FavoritesManager() {
    return _instance;
  }

  FavoritesManager._internal();

  Future<void> loadFavorites() async {
    final favorites = await _db.getFavorites();

    _favorites.clear();
    _favorites.addAll(favorites);
  }

  List<String> getFavorites() => _favorites.toList();

  bool isFavorite(String code) =>
      _favorites.contains(code);

  Future<void> addFavorite(String code) async {
    _favorites.add(code);
    await _db.addFavorite(code);
  }

  Future<void> removeFavorite(String code) async {
    _favorites.remove(code);
    await _db.removeFavorite(code);
  }

  Future<void> toggleFavorite(String code) async {
    if (isFavorite(code)) {
      await removeFavorite(code);
    } else {
      await addFavorite(code);
    }
  }
}