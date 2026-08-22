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

  testWidgets('hides email notification settings from the settings screen', (
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

    expect(find.text('🔔 E-Posta Bildirimleri'), findsNothing);
    expect(find.textContaining('Güncelleme Notları'), findsOneWidget);
    expect(find.textContaining('Bulut Yedekleme'), findsOneWidget);
  });

  testWidgets('keeps the app settings page functional without email controls', (
    tester,
  ) async {
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

    expect(find.text('🔔 E-Posta Bildirimleri'), findsNothing);
    expect(find.text('Google Hesabı: drive@example.com'), findsOneWidget);
    expect(find.textContaining('Bulut Yedekleme'), findsOneWidget);
  });

  testWidgets('shows up-to-date state on startup when cached version matches', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_update_check_timestamp': '2026-08-16T00:00:00.000',
      'last_update_available': true,
      'last_update_version_json':
          '{"version":"1.0.6","releaseDate":"2026-08-16","notes":["cached"],"apkUrl":"https://example.com/app.apk"}',
    });

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

    expect(find.text('✅ Uygulamanız güncel'), findsOneWidget);
    expect(find.text('🎉 Yeni sürüm mevcut'), findsNothing);
  });
}
