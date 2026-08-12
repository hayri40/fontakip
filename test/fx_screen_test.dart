import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fontakip/models/fx_asset.dart';
import 'package:fontakip/screens/fx_screen.dart';
import 'package:fontakip/services/fx_favorites_service.dart';
import 'package:fontakip/services/fx_market_service.dart';

class _FakeFxMarketService extends FxMarketService {
  const _FakeFxMarketService();

  @override
  Future<List<FxAsset>> searchAssets(String query) async {
    if (query.toUpperCase().contains('BTC')) {
      return const [
        FxAsset(
          id: 'BTC/USD',
          name: 'Bitcoin / Dolar',
          symbol: 'BTC/USD',
          currentPrice: 62000,
          type: FxAssetType.crypto,
        ),
      ];
    }
    return const [];
  }
}

class _InMemoryFxFavoritesService extends FxFavoritesService {
  final List<FxAsset> _items = <FxAsset>[];

  @override
  Future<List<FxAsset>> loadFavorites() async {
    return List<FxAsset>.from(_items);
  }

  @override
  Future<void> saveFavorites(List<FxAsset> items) async {
    _items
      ..clear()
      ..addAll(items);
  }
}

void main() {
  testWidgets('FX screen is search and favorites focused', (tester) async {
    final favoritesService = _InMemoryFxFavoritesService();

    await tester.pumpWidget(
      MaterialApp(
        home: FxScreen(
          marketService: const _FakeFxMarketService(),
          favoritesService: favoritesService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arama'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Favoriler'), findsOneWidget);
    expect(find.text('Arama Sonuçları'), findsNothing);

    await tester.enterText(find.byType(TextField), 'BTC');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Bitcoin / Dolar'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoriler'));
    await tester.pumpAndSettle();

    expect(find.text('Henüz favori enstrüman eklenmedi.'), findsNothing);
    expect(find.text('Bitcoin / Dolar'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
