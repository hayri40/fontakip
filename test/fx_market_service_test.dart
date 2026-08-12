import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fontakip/models/fx_asset.dart';
import 'package:fontakip/services/fx_market_service.dart';

void main() {
  test('ExchangeRate conversion_rates is used for USD/TRY detail', () async {
    SharedPreferences.setMockInitialValues({
      'data_source.fx.provider': 'ExchangeRate API',
      'data_source.fx.api_key': 'test_key',
    });

    final client = MockClient((request) async {
      if (request.url.path.contains('/latest/USD')) {
        return http.Response(
          jsonEncode({
            'result': 'success',
            'conversion_rates': {'USD': 1, 'TRY': 40.50, 'EUR': 0.9},
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    final service = FxMarketService(client: client);
    final detail = await service.getDetailBySymbol(
      symbol: 'USD/TRY',
      name: 'Amerikan Doları / Türk Lirası',
      type: FxAssetType.currency,
    );

    expect(detail.currentPrice, 40.50);
    expect(detail.dayHigh, 40.50);
    expect(detail.dayLow, 40.50);
  });
}
