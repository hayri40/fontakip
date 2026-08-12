import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fx_asset.dart';
import 'data_source_settings_service.dart';

class FxMarketService {
  final http.Client? _client;

  static const Map<String, String> _currencyNames = <String, String>{
    'USD': 'Amerikan Doları',
    'EUR': 'Euro',
    'GBP': 'İngiliz Sterlini',
    'TRY': 'Türk Lirası',
    'CHF': 'İsviçre Frangı',
    'JPY': 'Japon Yeni',
    'AUD': 'Avustralya Doları',
    'CAD': 'Kanada Doları',
    'NOK': 'Norveç Kronu',
    'SEK': 'İsveç Kronu',
    'DKK': 'Danimarka Kronu',
    'SAR': 'Suudi Riyali',
    'AED': 'BAE Dirhemi',
  };

  const FxMarketService({http.Client? client}) : _client = client;

  Future<List<FxAsset>> searchAssets(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const <FxAsset>[];
    }

    final config = await DataSourceSettingsService.instance.getFxSource();
    if (!config.isConfigured) {
      throw const MissingApiConfigException();
    }

    final apiKey = config.apiKey.trim();
    if (_isExchangeRateProvider(config.providerName)) {
      return _searchWithExchangeRate(query: normalized, apiKey: apiKey);
    }
    return _searchWithTwelveData(query: normalized, apiKey: apiKey);
  }

  Future<FxAsset> getDetailBySymbol({
    required String symbol,
    required String name,
    required FxAssetType type,
  }) async {
    final config = await DataSourceSettingsService.instance.getFxSource();
    if (!config.isConfigured) {
      throw const MissingApiConfigException();
    }

    final apiKey = config.apiKey.trim();
    if (_isExchangeRateProvider(config.providerName)) {
      final rates = await _fetchExchangeRates(apiKey: apiKey);
      if (rates.isEmpty) {
        throw Exception('FX verisi alınamadı.');
      }

      final price = _calculateExchangePairPrice(symbol: symbol, rates: rates);
      if (price == null) {
        throw Exception('Seçilen enstrüman için fiyat bilgisi bulunamadı.');
      }

      return FxAsset(
        id: symbol.toUpperCase(),
        name: name,
        symbol: symbol,
        currentPrice: price,
        changePercent: 0,
        dayHigh: price,
        dayLow: price,
        type: type,
      );
    }

    final quote = await _fetchTwelveQuote(symbol: symbol, apiKey: apiKey);
    return FxAsset(
      id: symbol.toUpperCase(),
      name: name,
      symbol: symbol,
      currentPrice: _toDouble(quote['close'] ?? quote['price']),
      changePercent: _toDouble(quote['percent_change']),
      dayHigh: _toDouble(quote['high']),
      dayLow: _toDouble(quote['low']),
      type: type,
    );
  }

  Future<List<FxAsset>> _searchWithExchangeRate({
    required String query,
    required String apiKey,
  }) async {
    final rates = await _fetchExchangeRates(apiKey: apiKey);
    if (rates.isEmpty) {
      throw Exception('FX verisi alınamadı.');
    }

    final normalizedQuery = _normalize(query);
    final matchedCodes = <String>{};

    for (final entry in rates.entries) {
      final code = entry.key.toUpperCase();
      final name = _normalize(_currencyNames[code] ?? code);
      if (code.contains(normalizedQuery) || name.contains(normalizedQuery)) {
        matchedCodes.add(code);
      }
    }

    final aliasMap = <String, String>{
      'DOLAR': 'USD',
      'EURO': 'EUR',
      'STERLIN': 'GBP',
      'INGILIZ': 'GBP',
      'FRANK': 'CHF',
      'YEN': 'JPY',
    };
    for (final alias in aliasMap.entries) {
      if (normalizedQuery.contains(alias.key)) {
        matchedCodes.add(alias.value);
      }
    }

    final assets = <FxAsset>[];
    for (final code in matchedCodes) {
      final symbol = _buildExchangeSymbol(code);
      final price = _calculateExchangePairPrice(symbol: symbol, rates: rates);
      if (price == null) {
        continue;
      }

      final codeName = _currencyNames[code] ?? code;
      assets.add(
        FxAsset(
          id: symbol.toUpperCase(),
          name: '$codeName / Türk Lirası',
          symbol: symbol,
          currentPrice: price,
          changePercent: 0,
          dayHigh: price,
          dayLow: price,
          type: FxAssetType.currency,
        ),
      );
    }

    if (assets.isEmpty) {
      final tryRate = rates['TRY'];
      if (tryRate != null) {
        final fallback = FxAsset(
          id: 'USD/TRY',
          name: 'Amerikan Doları / Türk Lirası',
          symbol: 'USD/TRY',
          currentPrice: tryRate,
          changePercent: 0,
          dayHigh: tryRate,
          dayLow: tryRate,
          type: FxAssetType.currency,
        );
        if (fallback.matchesQuery(query)) {
          assets.add(fallback);
        }
      }
    }

    return assets.take(20).toList();
  }

  Future<List<FxAsset>> _searchWithTwelveData({
    required String query,
    required String apiKey,
  }) async {
    final terms = _buildSearchTerms(query);
    final byId = <String, FxAsset>{};

    for (final term in terms) {
      final uri = Uri.parse(
        'https://api.twelvedata.com/symbol_search',
      ).replace(queryParameters: {'symbol': term, 'apikey': apiKey});

      final response = await _get(uri);
      if (response.statusCode != 200) {
        continue;
      }

      final decoded = _decodeMap(response.body);
      final status = (decoded['status'] ?? '').toString().toLowerCase();
      if (status == 'error') {
        continue;
      }

      final data = decoded['data'];
      if (data is! List) {
        continue;
      }

      for (final raw in data) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }

        final asset = await _toAssetFromSearchItem(raw, apiKey: apiKey);
        if (asset == null) {
          continue;
        }

        if (asset.matchesQuery(query) || _matchesAlias(asset, query)) {
          byId[asset.id] = asset;
        }
      }
    }

    return byId.values.take(20).toList();
  }

  Future<FxAsset?> _toAssetFromSearchItem(
    Map<String, dynamic> item, {
    required String apiKey,
  }) async {
    final symbol = (item['symbol'] ?? '').toString().trim();
    if (symbol.isEmpty) {
      return null;
    }

    final instrumentType = _resolveType(item);
    if (instrumentType == FxAssetType.other) {
      return null;
    }

    final name = _resolveName(item, symbol);
    final quote = await _fetchTwelveQuote(symbol: symbol, apiKey: apiKey);

    return FxAsset(
      id: symbol.toUpperCase(),
      name: name,
      symbol: symbol,
      currentPrice: _toDouble(quote['close'] ?? quote['price']),
      changePercent: _toDouble(quote['percent_change']),
      dayHigh: _toDouble(quote['high']),
      dayLow: _toDouble(quote['low']),
      type: instrumentType,
    );
  }

  Future<Map<String, double>> _fetchExchangeRates({
    required String apiKey,
  }) async {
    final uri = Uri.parse(
      'https://v6.exchangerate-api.com/v6/${apiKey.trim()}/latest/USD',
    );
    final response = await _get(uri);
    if (response.statusCode != 200) {
      return <String, double>{};
    }

    final decoded = _decodeMap(response.body);
    final result = (decoded['result'] ?? '').toString().toLowerCase();
    if (result != 'success') {
      return <String, double>{};
    }

    final conversionRates = decoded['conversion_rates'];
    if (conversionRates is! Map) {
      return <String, double>{};
    }

    final rates = <String, double>{};
    for (final entry in conversionRates.entries) {
      final code = entry.key.toString().toUpperCase();
      final value = _toDouble(entry.value);
      if (value != null && value > 0) {
        rates[code] = value;
      }
    }
    return rates;
  }

  Future<Map<String, dynamic>> _fetchTwelveQuote({
    required String symbol,
    required String apiKey,
  }) async {
    final uri = Uri.parse(
      'https://api.twelvedata.com/quote',
    ).replace(queryParameters: {'symbol': symbol, 'apikey': apiKey});
    final response = await _get(uri);
    if (response.statusCode != 200) {
      return <String, dynamic>{};
    }

    final decoded = _decodeMap(response.body);
    final status = (decoded['status'] ?? '').toString().toLowerCase();
    if (status == 'error') {
      return <String, dynamic>{};
    }
    return decoded;
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

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  bool _isExchangeRateProvider(String providerName) {
    final normalized = providerName.trim().toLowerCase();
    return normalized.contains('exchange') ||
        normalized.contains('exchangerate');
  }

  String _buildExchangeSymbol(String code) {
    final normalizedCode = code.toUpperCase();
    if (normalizedCode == 'USD' || normalizedCode == 'TRY') {
      return 'USD/TRY';
    }
    return '$normalizedCode/TRY';
  }

  double? _calculateExchangePairPrice({
    required String symbol,
    required Map<String, double> rates,
  }) {
    final parts = symbol.toUpperCase().split('/');
    if (parts.length != 2) {
      return null;
    }

    final base = parts[0];
    final quote = parts[1];
    final quoteRate = rates[quote];
    if (quoteRate == null || quoteRate <= 0) {
      return null;
    }

    if (base == 'USD') {
      return quoteRate;
    }

    final baseRate = rates[base];
    if (baseRate == null || baseRate <= 0) {
      return null;
    }
    return quoteRate / baseRate;
  }

  List<String> _buildSearchTerms(String query) {
    final normalized = _normalize(query);
    final terms = <String>{query.toUpperCase()};
    if (normalized.contains('ALTIN')) {
      terms.addAll(<String>['GOLD', 'XAU']);
    }
    if (normalized.contains('GUMUS')) {
      terms.addAll(<String>['SILVER', 'XAG']);
    }
    if (normalized.contains('PETROL')) {
      terms.addAll(<String>['BRENT', 'CRUDE', 'OIL']);
    }
    if (normalized.contains('BITCOIN')) {
      terms.add('BTC');
    }
    if (normalized.contains('ETHEREUM')) {
      terms.add('ETH');
    }
    if (normalized.contains('DOLAR')) {
      terms.add('USD');
    }
    if (normalized.contains('EURO')) {
      terms.add('EUR');
    }
    return terms.toList();
  }

  FxAssetType _resolveType(Map<String, dynamic> item) {
    final typeText =
        (item['instrument_type'] ??
                item['type'] ??
                item['asset_type'] ??
                item['currency_base'])
            .toString()
            .toLowerCase();
    final symbol = (item['symbol'] ?? '').toString().toUpperCase();
    final currency = (item['currency'] ?? '').toString().toUpperCase();

    if (typeText.contains('crypto') ||
        typeText.contains('digital') ||
        symbol.endsWith('/USD') && _isCryptoBase(symbol.split('/').first)) {
      return FxAssetType.crypto;
    }
    if (typeText.contains('commodity') ||
        typeText.contains('metal') ||
        symbol.contains('XAU') ||
        symbol.contains('XAG') ||
        symbol.contains('BRENT') ||
        symbol.contains('WTI') ||
        symbol.contains('NATGAS')) {
      return FxAssetType.commodity;
    }
    if (typeText.contains('forex') ||
        typeText.contains('currency') ||
        currency.isNotEmpty ||
        symbol.contains('/')) {
      return FxAssetType.currency;
    }
    return FxAssetType.other;
  }

  String _resolveName(Map<String, dynamic> item, String fallbackSymbol) {
    final directName =
        (item['instrument_name'] ?? item['name'] ?? item['description'] ?? '')
            .toString()
            .trim();
    if (directName.isNotEmpty) {
      return directName;
    }
    final base = (item['currency_base'] ?? '').toString().trim();
    final quote = (item['currency_quote'] ?? '').toString().trim();
    if (base.isNotEmpty && quote.isNotEmpty) {
      return '$base / $quote';
    }
    return fallbackSymbol;
  }

  bool _isCryptoBase(String base) {
    return const <String>{
      'BTC',
      'ETH',
      'BNB',
      'SOL',
      'XRP',
      'AVAX',
      'DOGE',
      'ADA',
      'DOT',
      'LTC',
    }.contains(base.toUpperCase());
  }

  bool _matchesAlias(FxAsset asset, String query) {
    final normalized = _normalize(query);
    final symbol = asset.symbol.toUpperCase();
    final name = _normalize(asset.name);
    if (normalized.contains('ALTIN')) {
      return symbol.contains('XAU') || name.contains('GOLD');
    }
    if (normalized.contains('GUMUS')) {
      return symbol.contains('XAG') || name.contains('SILVER');
    }
    if (normalized.contains('PETROL')) {
      return symbol.contains('BRENT') || name.contains('OIL');
    }
    if (normalized.contains('BITCOIN')) {
      return symbol.contains('BTC');
    }
    if (normalized.contains('ETHEREUM')) {
      return symbol.contains('ETH');
    }
    if (normalized.contains('DOLAR')) {
      return symbol.contains('USD');
    }
    if (normalized.contains('EURO')) {
      return symbol.contains('EUR');
    }
    if (normalized.contains('STERLIN')) {
      return symbol.contains('GBP');
    }
    return false;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('İ', 'I')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
