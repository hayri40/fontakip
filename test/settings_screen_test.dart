import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fontakip/models/auth_state.dart';
import 'package:fontakip/models/cloud_backup_info.dart';
import 'package:fontakip/models/user_account.dart';
import 'package:fontakip/screens/settings_screen.dart';
import 'package:fontakip/services/cloud_backup_service.dart';
import 'package:fontakip/services/email_summary_preferences_service.dart';

class _FakeCloudBackupService implements CloudBackupService {
  _FakeCloudBackupService({
    required AuthState authState,
    required CloudBackupInfo backupInfo,
  }) : _authState = authState,
       _backupInfo = backupInfo;

  final AuthState _authState;
  final CloudBackupInfo _backupInfo;

  @override
  bool get isSignedIn => _authState.isSignedIn;

  @override
  Future<CloudRestoreData> downloadBackup() {
    throw UnimplementedError();
  }

  @override
  Future<AuthState> getAuthState() async => _authState;

  @override
  Future<CloudBackupInfo> getBackupInfo() async => _backupInfo;

  @override
  Future<void> restoreBackupData(String rawJson) {
    throw UnimplementedError();
  }

  @override
  Future<AuthState> signIn({String? email}) async => _authState;

  @override
  Future<void> signOut() async {}

  @override
  Future<CloudBackupInfo> uploadBackup() {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'FontTakip',
      packageName: 'com.fontakip.app',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  testWidgets('shows Google requirement message for email notifications', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          cloudBackupService: _FakeCloudBackupService(
            authState: const AuthState(isSignedIn: false, provider: 'google'),
            backupInfo: const CloudBackupInfo(
              provider: 'google',
              isSignedIn: false,
            ),
          ),
          emailSummaryPreferencesService:
              SharedPreferencesEmailSummaryPreferencesService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('🔔 E-Posta Bildirimleri'), findsOneWidget);
    expect(
      find.text('Bu özellik için Google hesabı gereklidir.'),
      findsOneWidget,
    );
    expect(
      find.text('Gönderilecek Adres: Google hesabı gerekli'),
      findsOneWidget,
    );
  });

  testWidgets('shows signed-in email summary preferences and persists toggle', (
    tester,
  ) async {
    final prefs = <String, Object>{
      'email_summary_fund_time': '09:30',
      'email_summary_stock_time': '18:30',
      'email_summary_fund_last_sent_at': '2026-08-13T09:30:00.000',
    };
    SharedPreferences.setMockInitialValues(prefs);
    final user = UserAccount(
      id: 'user-1',
      email: 'drive@example.com',
      provider: 'google',
      createdAt: DateTime(2026, 8, 13),
      displayName: 'Drive User',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          cloudBackupService: _FakeCloudBackupService(
            authState: AuthState(
              isSignedIn: true,
              provider: 'google',
              user: user,
            ),
            backupInfo: CloudBackupInfo(
              provider: 'google',
              isSignedIn: true,
              user: user,
            ),
          ),
          emailSummaryPreferencesService:
              SharedPreferencesEmailSummaryPreferencesService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gönderilecek Adres: drive@example.com'), findsOneWidget);
    expect(find.text('Saat: 09:30'), findsOneWidget);
    expect(find.text('Saat: 18:30'), findsOneWidget);
    expect(
      find.textContaining('Son Gönderim: 13.08.2026 09:30'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final sharedPreferences = await SharedPreferences.getInstance();
    expect(sharedPreferences.getBool('email_summary_fund_enabled'), isTrue);
  });
}
