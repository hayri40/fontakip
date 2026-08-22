class StockRequestBuilder {
  const StockRequestBuilder._();

  static String buildSymbol(String rawSymbol, {required bool appendDotIs}) {
    final symbol = rawSymbol.trim().toUpperCase().replaceAll('.IS', '');
    if (appendDotIs) {
      return '$symbol.IS';
    }
    return symbol;
  }

  static Uri buildUri({
    required String apiUrl,
    required String apiKey,
    required String rawSymbol,
    required bool appendDotIs,
  }) {
    final symbol = buildSymbol(rawSymbol, appendDotIs: appendDotIs);
    final url = apiUrl.trim();

    if (url.contains('{symbol}') || url.contains('{apiKey}')) {
      return Uri.parse(
        url
            .replaceAll('{symbol}', Uri.encodeComponent(symbol))
            .replaceAll('{apiKey}', Uri.encodeComponent(apiKey)),
      );
    }

    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (host.contains('twelvedata.com')) {
      return uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'symbol': symbol,
          'apikey': apiKey,
        },
      );
    }

    if (host.contains('marketstack.com')) {
      final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      return Uri.parse(
        '$base/$symbol/eod/latest?access_key=${Uri.encodeQueryComponent(apiKey)}',
      );
    }

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'symbol': symbol,
        'apikey': apiKey,
      },
    );
  }

  static bool hasMeaningfulData(dynamic json) {
    return _containsAnyKey(json, const {'symbol', 'close', 'price', 'exchange'});
  }

  static bool _containsAnyKey(dynamic value, Set<String> keys) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        if (keys.contains(key)) {
          final v = entry.value;
          if (v != null && v.toString().trim().isNotEmpty) {
            return true;
          }
        }
        if (_containsAnyKey(entry.value, keys)) {
          return true;
        }
      }
    } else if (value is List) {
      for (final item in value) {
        if (_containsAnyKey(item, keys)) {
          return true;
        }
      }
    }
    return false;
  }
}
