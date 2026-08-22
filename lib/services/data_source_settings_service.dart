import 'package:shared_preferences/shared_preferences.dart';

const String kMissingApiConfigMessage =
    'Bu veri kaynağı için API bilgisi tanımlanmamış. Ayarlar > Veri Kaynakları bölümünden bilgileri giriniz.';

class MissingApiConfigException implements Exception {
  const MissingApiConfigException();

  @override
  String toString() => kMissingApiConfigMessage;
}

class DataSourceConfig {
  final String providerName;
  final String apiKey;

  const DataSourceConfig({
    required this.providerName,
    required this.apiKey,
  });

  bool get isConfigured => providerName.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

class StockDataSourceConfig {
  final String apiUrl;
  final String apiKey;
  final bool appendDotIs;

  const StockDataSourceConfig({
    required this.apiUrl,
    required this.apiKey,
    required this.appendDotIs,
  });

  bool get isConfigured => apiUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

class DataSourceSettingsService {
  static const _fundProviderKey = 'data_source.fund.provider';
  static const _fundApiKeyKey = 'data_source.fund.api_key';
  static const _stockProviderKey = 'data_source.stock.provider'; // legacy
  static const _stockApiUrlKey = 'data_source.stock.api_url';
  static const _stockApiKeyKey = 'data_source.stock.api_key';
  static const _stockAppendDotIsKey = 'data_source.stock.append_dot_is';
  static const _fxProviderKey = 'data_source.fx.provider';
  static const _fxApiKeyKey = 'data_source.fx.api_key';

  static final DataSourceSettingsService instance = DataSourceSettingsService._();

  DataSourceSettingsService._();

  Future<DataSourceConfig> getFundSource() async {
    final prefs = await SharedPreferences.getInstance();
    return DataSourceConfig(
      providerName: prefs.getString(_fundProviderKey) ?? '',
      apiKey: prefs.getString(_fundApiKeyKey) ?? '',
    );
  }

  Future<StockDataSourceConfig> getStockSource() async {
    final prefs = await SharedPreferences.getInstance();
    return StockDataSourceConfig(
      apiUrl: prefs.getString(_stockApiUrlKey) ?? prefs.getString(_stockProviderKey) ?? '',
      apiKey: prefs.getString(_stockApiKeyKey) ?? '',
      appendDotIs: prefs.getBool(_stockAppendDotIsKey) ?? false,
    );
  }

  Future<DataSourceConfig> getFxSource() async {
    final prefs = await SharedPreferences.getInstance();
    return DataSourceConfig(
      providerName: prefs.getString(_fxProviderKey) ?? '',
      apiKey: prefs.getString(_fxApiKeyKey) ?? '',
    );
  }

  Future<void> saveFundSource({
    required String providerName,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fundProviderKey, providerName.trim());
    await prefs.setString(_fundApiKeyKey, apiKey.trim());
  }

  Future<void> saveStockSource({
    required String apiUrl,
    required String apiKey,
    required bool appendDotIs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stockApiUrlKey, apiUrl.trim());
    await prefs.setString(_stockApiKeyKey, apiKey.trim());
    await prefs.setBool(_stockAppendDotIsKey, appendDotIs);
  }

  Future<void> saveFxSource({
    required String providerName,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fxProviderKey, providerName.trim());
    await prefs.setString(_fxApiKeyKey, apiKey.trim());
  }
}
