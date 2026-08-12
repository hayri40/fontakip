import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fontakip/services/stock_service.dart';

void main() {
  setUp(() {
    StockService.clearCacheForTesting();
  });

  test('returns fallback stock when price is unavailable and cache is empty',
      () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'status': 'error',
          'message':
              'This symbol is available starting with the Grow or Venture plan',
        }),
        200,
      );
    });

    final service = StockService(
      client: client,
      apiKey: 'test-key',
    );

    final stock = await service.getStockDetail('THYAO');

    expect(stock.symbol, 'THYAO');
    expect(stock.name, 'Turk Hava Yollari');
    expect(stock.currentPrice, isNull);
    expect(
      stock.priceUnavailableMessage,
      'Bu sembol için ücretsiz veri sağlayıcısında fiyat bilgisi bulunamadı.',
    );
  });

  test('keeps last successful price when later requests fail', () async {
    var callCount = 0;
    final client = MockClient((request) async {
      callCount += 1;
      if (callCount == 1) {
        return http.Response(
          jsonEncode({
            'symbol': 'THYAO',
            'name': 'Turk Hava Yollari',
            'close': 100.5,
            'status': 'ok',
          }),
          200,
        );
      }

      return http.Response(
        jsonEncode({
          'status': 'error',
          'message':
              'This symbol is available starting with the Grow or Venture plan',
        }),
        200,
      );
    });

    final service = StockService(
      client: client,
      apiKey: 'test-key',
    );

    final first = await service.getStockDetail('THYAO');
    final second = await service.getStockDetail('THYAO');

    expect(first.currentPrice, 100.5);
    expect(second.currentPrice, 100.5);
    expect(
      second.priceUnavailableMessage,
      'Bu sembol için ücretsiz veri sağlayıcısında fiyat bilgisi bulunamadı.',
    );
  });

  test('uses price endpoint with raw THYAO symbol', () async {
    final urls = <Uri>[];
    final client = MockClient((request) async {
      urls.add(request.url);
      return http.Response(
        jsonEncode({
          'status': 'error',
          'message':
              'This symbol is available starting with the Grow or Venture plan',
        }),
        200,
      );
    });

    final service = StockService(
      client: client,
      apiKey: 'test-key',
    );

    await service.getStockDetail('THYAO');

    expect(urls, hasLength(1));
    expect(
      urls.single.toString(),
      'https://api.twelvedata.com/price?symbol=THYAO&apikey=test-key',
    );
  });

  test('searchStocks forwards THYAO without BIST suffix', () async {
    final urls = <Uri>[];
    final client = MockClient((request) async {
      urls.add(request.url);
      return http.Response(
        jsonEncode({
          'status': 'error',
          'message':
              'This symbol is available starting with the Grow or Venture plan',
        }),
        200,
      );
    });

    final service = StockService(
      client: client,
      apiKey: 'test-key',
    );

    await service.searchStocks('thy');

    expect(urls, isNotEmpty);
    expect(
      urls.first.toString(),
      'https://api.twelvedata.com/price?symbol=THYAO&apikey=test-key',
    );
    expect(urls.any((uri) => uri.toString().contains('BIST')), isFalse);
  });
}
