import 'package:shared_preferences/shared_preferences.dart';

import '../models/email_summary_preferences.dart';

abstract class EmailSummaryPreferencesService {
  Future<EmailSummaryPreferences> load();
  Future<EmailSummaryPreferences> save(EmailSummaryPreferences preferences);
}

class SharedPreferencesEmailSummaryPreferencesService
    implements EmailSummaryPreferencesService {
  static const String _fundEnabledKey = 'email_summary_fund_enabled';
  static const String _fundTimeKey = 'email_summary_fund_time';
  static const String _fundLastSentAtKey = 'email_summary_fund_last_sent_at';
  static const String _stockEnabledKey = 'email_summary_stock_enabled';
  static const String _stockTimeKey = 'email_summary_stock_time';
  static const String _stockLastSentAtKey = 'email_summary_stock_last_sent_at';

  final Future<SharedPreferences> _prefsFuture;

  SharedPreferencesEmailSummaryPreferencesService({
    Future<SharedPreferences>? prefsFuture,
  }) : _prefsFuture = prefsFuture ?? SharedPreferences.getInstance();

  @override
  Future<EmailSummaryPreferences> load() async {
    final prefs = await _prefsFuture;
    return EmailSummaryPreferences(
      fundSummaryEnabled: prefs.getBool(_fundEnabledKey) ?? false,
      fundSummaryTime: _normalizeTime(
        prefs.getString(_fundTimeKey),
        fallback: '09:30',
      ),
      lastFundSummarySentAt: _parseDateTime(
        prefs.getString(_fundLastSentAtKey),
      ),
      stockSummaryEnabled: prefs.getBool(_stockEnabledKey) ?? false,
      stockSummaryTime: _normalizeTime(
        prefs.getString(_stockTimeKey),
        fallback: '18:30',
      ),
      lastStockSummarySentAt: _parseDateTime(
        prefs.getString(_stockLastSentAtKey),
      ),
    );
  }

  @override
  Future<EmailSummaryPreferences> save(
    EmailSummaryPreferences preferences,
  ) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_fundEnabledKey, preferences.fundSummaryEnabled);
    await prefs.setString(
      _fundTimeKey,
      _normalizeTime(preferences.fundSummaryTime, fallback: '09:30'),
    );
    await _setOptionalDateTime(
      prefs: prefs,
      key: _fundLastSentAtKey,
      value: preferences.lastFundSummarySentAt,
    );
    await prefs.setBool(_stockEnabledKey, preferences.stockSummaryEnabled);
    await prefs.setString(
      _stockTimeKey,
      _normalizeTime(preferences.stockSummaryTime, fallback: '18:30'),
    );
    await _setOptionalDateTime(
      prefs: prefs,
      key: _stockLastSentAtKey,
      value: preferences.lastStockSummarySentAt,
    );
    return load();
  }

  Future<void> _setOptionalDateTime({
    required SharedPreferences prefs,
    required String key,
    required DateTime? value,
  }) async {
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.toIso8601String());
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String _normalizeTime(String? raw, {required String fallback}) {
    final value = raw?.trim() ?? '';
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      return fallback;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return fallback;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return fallback;
    }

    final normalizedHour = hour.toString().padLeft(2, '0');
    final normalizedMinute = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$normalizedMinute';
  }
}
