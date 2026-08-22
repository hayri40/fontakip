import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fontakip/services/email_summary_preferences_service.dart';
import 'package:fontakip/models/email_summary_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads default daily email summary preferences', () async {
    final service = SharedPreferencesEmailSummaryPreferencesService();

    final preferences = await service.load();

    expect(preferences.fundSummaryEnabled, isFalse);
    expect(preferences.fundSummaryTime, '09:30');
    expect(preferences.stockSummaryEnabled, isFalse);
    expect(preferences.stockSummaryTime, '18:30');
    expect(preferences.lastFundSummarySentAt, isNull);
    expect(preferences.lastStockSummarySentAt, isNull);
  });

  test('saves and reloads daily email summary preferences', () async {
    final service = SharedPreferencesEmailSummaryPreferencesService();
    final value = EmailSummaryPreferences(
      fundSummaryEnabled: true,
      fundSummaryTime: '08:45',
      lastFundSummarySentAt: DateTime.parse('2026-08-13T09:30:00.000Z'),
      stockSummaryEnabled: true,
      stockSummaryTime: '19:10',
      lastStockSummarySentAt: DateTime.parse('2026-08-13T18:30:00.000Z'),
    );

    await service.save(value);
    final loaded = await service.load();

    expect(loaded.fundSummaryEnabled, isTrue);
    expect(loaded.fundSummaryTime, '08:45');
    expect(
      loaded.lastFundSummarySentAt,
      DateTime.parse('2026-08-13T09:30:00.000Z'),
    );
    expect(loaded.stockSummaryEnabled, isTrue);
    expect(loaded.stockSummaryTime, '19:10');
    expect(
      loaded.lastStockSummarySentAt,
      DateTime.parse('2026-08-13T18:30:00.000Z'),
    );
  });
}
