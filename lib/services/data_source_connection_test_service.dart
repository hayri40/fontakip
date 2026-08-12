import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'data_source_settings_service.dart';
import 'stock_request_builder.dart';

class DataSourceConnectionTestService {
  final http.Client? _client;

  const DataSourceConnectionTestService({http.Client? client}) : _client = client;

  Future<String> testFundConnection({
    required String providerName,
    required String apiKey,
  }) async {
    if (providerName.trim().isEmpty || apiKey.trim().isEmpty) {
      return kMissingApiConfigMessage;
    }

    try {
      final response = await _get(
        Uri.parse('https://fonoloji.com/v1/funds/KLU'),
        headers: {
          'X-API-Key': apiKey.trim(),
        },
      );

      if (response.statusCode == 200) {
        return '✅ Bağlantı başarılı';
      }
      return _mapError(response.statusCode, response.body);
    } catch (_) {
      return '❌ Servise ulaşılamadı';
    }
  }

  Future<String> testStockConnection({
    required String apiUrl,
    required String apiKey,
    required bool appendDotIs,
  }) async {
    if (apiUrl.trim().isEmpty || apiKey.trim().isEmpty) {
      return kMissingApiConfigMessage;
    }

    try {
      final uri = StockRequestBuilder.buildUri(
        apiUrl: apiUrl,
        apiKey: apiKey,
        rawSymbol: 'THYAO',
        appendDotIs: appendDotIs,
      );
      final response = await _get(
        uri,
      );

      if (response.statusCode == 200) {
        final decoded = _tryDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final status = (decoded['status'] ?? decoded['result'] ?? '')
              .toString()
              .toLowerCase();
          if (status == 'error') {
            return _mapError(response.statusCode, response.body);
          }
        }
        if (StockRequestBuilder.hasMeaningfulData(decoded)) {
          return '✅ Bağlantı başarılı';
        }
        return '❌ Servise ulaşılamadı';
      }
      return _mapError(response.statusCode, response.body);
    } catch (_) {
      return '❌ Servise ulaşılamadı';
    }
  }

  Future<String> testFxConnection({
    required String providerName,
    required String apiKey,
  }) async {
    if (providerName.trim().isEmpty || apiKey.trim().isEmpty) {
      return kMissingApiConfigMessage;
    }

    try {
      final response = await _get(
        Uri.parse('https://v6.exchangerate-api.com/v6/${apiKey.trim()}/latest/USD'),
      );

      if (response.statusCode == 200) {
        final decoded = _tryDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final result = (decoded['result'] ?? '').toString().toLowerCase();
          if (result == 'success') {
            return '✅ Bağlantı başarılı';
          }
          return _mapError(response.statusCode, response.body);
        }
      }
      return _mapError(response.statusCode, response.body);
    } catch (_) {
      return '❌ Servise ulaşılamadı';
    }
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final client = _client ?? http.Client();
    if (_client != null) {
      return client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    }

    try {
      return await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const SocketException('timeout');
    } finally {
      client.close();
    }
  }

  String _mapError(int statusCode, String body) {
    final raw = body.toLowerCase();
    final decoded = _tryDecode(body);
    final message = decoded is Map<String, dynamic>
        ? (decoded['message'] ??
                decoded['error'] ??
                decoded['error-type'] ??
                decoded['detail'] ??
                '')
            .toString()
            .toLowerCase()
        : '';

    final joined = '$raw $message';
    if (statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 400 ||
        joined.contains('invalid') ||
        joined.contains('unauthorized') ||
        joined.contains('api key') ||
        joined.contains('apikey')) {
      return '❌ API anahtarı geçersiz';
    }

    if (statusCode == 429 ||
        joined.contains('quota') ||
        joined.contains('limit') ||
        joined.contains('too many')) {
      return '❌ Kota limiti aşılmış olabilir';
    }

    return '❌ Servise ulaşılamadı';
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
