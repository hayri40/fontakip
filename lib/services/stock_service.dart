import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/stock.dart';
import 'data_source_settings_service.dart';
import 'stock_request_builder.dart';

class _TwelveDataPlanRestrictionException implements Exception {
  final String userMessage;

  const _TwelveDataPlanRestrictionException(this.userMessage);

  @override
  String toString() => userMessage;
}

class StockService {
  static const String _defaultStockApiUrl = 'https://api.twelvedata.com/price';
  static const String _planRestrictionText =
      'This symbol is available starting with the Grow or Venture plan';
  static const String _freePlanPriceMessage =
      'Bu sembol için ücretsiz veri sağlayıcısında fiyat bilgisi bulunamadı.';
  static const String _genericPriceMessage =
      'Bu sembol için fiyat bilgisi şu anda alınamadı.';
  final http.Client? _client;
  final String? _apiKeyOverride;
  static final Map<String, Stock> _stockCache = <String, Stock>{};

  StockService({this._client, String? apiKey})
      : _apiKeyOverride = apiKey;

  static const List<Map<String, String>> _bistStocks = [
    {'symbol': 'THYAO', 'name': 'Turk Hava Yollari'},
    {'symbol': 'ASELS', 'name': 'Aselsan'},
    {'symbol': 'EREGL', 'name': 'Eregli Demir Celik'},
    {'symbol': 'TUPRS', 'name': 'Tupras'},
    {'symbol': 'SISE', 'name': 'Sise Cam'},
    {'symbol': 'KCHOL', 'name': 'Koc Holding'},
    {'symbol': 'GARAN', 'name': 'Garanti BBVA'},
    {'symbol': 'AKBNK', 'name': 'Akbank'},
    {'symbol': 'YKBNK', 'name': 'Yapi Kredi'},
    {'symbol': 'ISCTR', 'name': 'Is Bankasi'},
    {'symbol': 'BIMAS', 'name': 'Bim Magazalar'},
    {'symbol': 'SASA', 'name': 'Sasa Polyester'},
    {'symbol': 'HEKTS', 'name': 'HektaS'},
    {'symbol': 'PETKM', 'name': 'Petkim'},
    {'symbol': 'KOZAL', 'name': 'Koza Altin'},
    {'symbol': 'KOZAA', 'name': 'Koza Anadolu'},
    {'symbol': 'FROTO', 'name': 'Ford Otosan'},
    {'symbol': 'TOASO', 'name': 'Tofas'},
    {'symbol': 'ENKAI', 'name': 'Enka Insaat'},
    {'symbol': 'MGROS', 'name': 'Migros'},
    {'symbol': 'BASGZ', 'name': 'Baskent Gaz'},
  ];

  Future<List<Stock>> searchStocks(String query) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final matched = _bistStocks.where((item) {
      final symbol = _normalize(item['symbol'] ?? '');
      final name = _normalize(item['name'] ?? '');
      return symbol.contains(normalizedQuery) || name.contains(normalizedQuery);
    }).toList();

    final futures = matched.map((item) async {
      final symbol = item['symbol']!;
      final fallbackName = item['name']!;
      try {
        return await getStockDetail(symbol);
      } on MissingApiConfigException catch (e) {
        return _buildFallbackFromCache(
          symbol: symbol,
          fallbackName: fallbackName,
          priceUnavailableMessage: e.toString(),
        );
      } on _TwelveDataPlanRestrictionException catch (e) {
        return _buildFallbackFromCache(
          symbol: symbol,
          fallbackName: fallbackName,
          priceUnavailableMessage: e.userMessage,
        );
      } catch (_) {
        return _buildFallbackFromCache(
          symbol: symbol,
          fallbackName: fallbackName,
          priceUnavailableMessage: _genericPriceMessage,
        );
      }
    });

    return Future.wait(futures);
  }

  Future<Stock> getStockDetail(String symbol) async {
    final normalizedSymbol = symbol.trim().toUpperCase().replaceAll('.IS', '');
    final fallbackName = _bistStocks
        .firstWhere(
          (e) => e['symbol'] == normalizedSymbol,
          orElse: () => {'symbol': normalizedSymbol, 'name': normalizedSymbol},
        )['name']!;

    try {
      final price = await _fetchPrice(normalizedSymbol);
      final stock = Stock.fromJson({
        'symbol': normalizedSymbol,
        'name': price['name'] ?? fallbackName,
        'sector': 'BIST',
        'current_price': price['price'] ?? price['close'],
        'previous_close': price['previous_close'],
        'day_high': price['high'],
        'day_low': price['low'],
        'market_cap': price['market_cap'],
        'pe_ratio': price['pe'],
        'eps': price['eps'],
      });

      _cacheSuccessfulStock(stock);
      return stock;
    } on MissingApiConfigException catch (e) {
      return _buildFallbackFromCache(
        symbol: normalizedSymbol,
        fallbackName: fallbackName,
        priceUnavailableMessage: e.toString(),
      );
    } on _TwelveDataPlanRestrictionException catch (e) {
      return _buildFallbackFromCache(
        symbol: normalizedSymbol,
        fallbackName: fallbackName,
        priceUnavailableMessage: e.userMessage,
      );
    } catch (_) {
      return _buildFallbackFromCache(
        symbol: normalizedSymbol,
        fallbackName: fallbackName,
        priceUnavailableMessage: _genericPriceMessage,
      );
    }
  }

  Future<Map<String, dynamic>> _fetchPrice(String symbolForApi) async {
    final config = await _resolveStockConfig();

    final response = await _get(
      _buildPriceUri(
        rawSymbol: symbolForApi,
        apiUrl: config.apiUrl,
        apiKey: config.apiKey,
        appendDotIs: config.appendDotIs,
      ),
    );

    if (response.statusCode != 200) {
      final errorMessage = _extractMessage(response.body);
      if (errorMessage.contains(_planRestrictionText)) {
        throw _TwelveDataPlanRestrictionException(_freePlanPriceMessage);
      }

      throw Exception(
        'Hisse detayı alınamadı. Status: ${response.statusCode} Body: $errorMessage',
      );
    }

    final decoded = jsonDecode(response.body);
    final json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final status = (json['status'] ?? json['result'] ?? '').toString().toLowerCase();
    if (status == 'error') {
      final errorMessage = _extractMessage(response.body, json);
      if (errorMessage.contains(_planRestrictionText)) {
        throw _TwelveDataPlanRestrictionException(_freePlanPriceMessage);
      }

      throw Exception('Hisse detayı alınamadı. $errorMessage');
    }

    return _extractStockPayload(decoded);
  }

  static void clearCacheForTesting() {
    _stockCache.clear();
  }

  Future<http.Response> _get(Uri uri) async {
    final client = _client ?? http.Client();
    if (_client != null) {
      return client.get(uri);
    }

    try {
      return await client.get(uri);
    } finally {
      client.close();
    }
  }

  Future<StockDataSourceConfig> _resolveStockConfig() async {
    final override = _apiKeyOverride?.trim() ?? '';
    if (override.isNotEmpty) {
      return StockDataSourceConfig(
        apiUrl: _defaultStockApiUrl,
        apiKey: override,
        appendDotIs: false,
      );
    }

    final source = await DataSourceSettingsService.instance.getStockSource();
    if (!source.isConfigured) {
      throw const MissingApiConfigException();
    }
    return source;
  }

  Uri _buildPriceUri({
    required String rawSymbol,
    required String apiUrl,
    required String apiKey,
    required bool appendDotIs,
  }) {
    return StockRequestBuilder.buildUri(
      apiUrl: apiUrl,
      apiKey: apiKey,
      rawSymbol: rawSymbol,
      appendDotIs: appendDotIs,
    );
  }

  Map<String, dynamic> _extractStockPayload(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (_hasAnyValue(decoded, const ['price', 'close', 'symbol', 'exchange'])) {
        return decoded;
      }
      final data = decoded['data'];
      if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
        return data.first as Map<String, dynamic>;
      }
      if (data is Map<String, dynamic>) {
        return data;
      }
    }

    if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
      return decoded.first as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  bool _hasAnyValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  void _cacheSuccessfulStock(Stock stock) {
    if (stock.currentPrice == null) {
      return;
    }

    _stockCache[stock.symbol] = stock.copyWith(
      priceUnavailableMessage: null,
    );
  }

  Stock _buildFallbackFromCache({
    required String symbol,
    required String fallbackName,
    required String priceUnavailableMessage,
  }) {
    final cachedStock = _stockCache[symbol];
    if (cachedStock != null) {
      return cachedStock.copyWith(
        priceUnavailableMessage: priceUnavailableMessage,
      );
    }

    return Stock(
      symbol: symbol,
      name: fallbackName,
      sector: 'BIST',
      priceUnavailableMessage: priceUnavailableMessage,
    );
  }

  String _extractMessage(
    String rawBody, [
    Map<String, dynamic>? json,
  ]) {
    if (json != null) {
      final message = (json['message'] ?? json['error'] ?? '').toString();
      if (message.isNotEmpty) {
        return message;
      }
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final message =
            (decoded['message'] ?? decoded['error'] ?? rawBody).toString();
        return message.isNotEmpty ? message : rawBody;
      }
    } catch (_) {
      // Fall through to the raw body.
    }

    return rawBody;
  }

  String _normalize(String text) {
    return text
        .trim()
        .toUpperCase()
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('İ', 'I')
        .replaceAll('I', 'I')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }
}
