import 'dart:convert';

import '../models/fx_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FxFavoritesService {
  static const String _prefsKey = 'fx_favorites';

  Future<List<FxAsset>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_prefsKey) ?? const <String>[];
    final items = <FxAsset>[];
    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          items.add(FxAsset.fromJson(decoded));
        }
      } catch (_) {
        // Skip invalid items.
      }
    }
    return items;
  }

  Future<void> saveFavorites(List<FxAsset> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_prefsKey, encoded);
  }

  Future<bool> isFavorite(String id) async {
    final items = await loadFavorites();
    return items.any((item) => item.id == id);
  }

  Future<void> toggleFavorite(FxAsset asset) async {
    final items = await loadFavorites();
    final existingIndex = items.indexWhere((item) => item.id == asset.id);
    if (existingIndex >= 0) {
      items.removeAt(existingIndex);
    } else {
      items.add(asset);
    }
    await saveFavorites(items);
  }

  Future<void> upsertFavorite(FxAsset asset) async {
    final items = await loadFavorites();
    final existingIndex = items.indexWhere((item) => item.id == asset.id);
    if (existingIndex >= 0) {
      items[existingIndex] = asset;
    } else {
      items.add(asset);
    }
    await saveFavorites(items);
  }
}
