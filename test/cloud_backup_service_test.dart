import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fontakip/models/user_account.dart';
import 'package:fontakip/services/backup_service.dart';
import 'package:fontakip/services/cloud_backup_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBackupService extends BackupService {
  _FakeBackupService({required this.exportJson});

  final String exportJson;
  String? importedJson;

  @override
  Future<String> createBackupJson({bool pretty = false}) async => exportJson;

  @override
  Future<void> importBackupFromJson(String raw) async {
    importedJson = raw;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final user = UserAccount(
    id: 'user-1',
    email: 'drive@example.com',
    provider: 'google',
    createdAt: DateTime(2026, 8, 13),
    displayName: 'Drive User',
  );

  DriveUserSession buildSession() {
    return DriveUserSession(
      user: user,
      authHeadersProvider: () async => const <String, String>{
        'Authorization': 'Bearer test-token',
      },
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('uploadBackup updates existing AppData backup file', () async {
    final requests = <http.Request>[];
    final service = GoogleCloudBackupService(
      backupService: _FakeBackupService(exportJson: '{"hello":"world"}'),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'files': [
                {
                  'id': 'existing-backup',
                  'modifiedTime': '2026-08-13T12:00:00.000Z',
                  'size': '12',
                },
              ],
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'id': 'existing-backup',
            'modifiedTime': '2026-08-13T13:00:00.000Z',
            'size': '17',
          }),
          200,
        );
      }),
      interactiveSignIn: () async => buildSession(),
      silentSignIn: () async => buildSession(),
      canAccessScopes: (_) async => true,
      requestScopes: (_) async => true,
    );

    final info = await service.uploadBackup();

    expect(info.hasBackup, isTrue);
    expect(info.user?.email, 'drive@example.com');
    expect(info.backupSizeBytes, 17);
    expect(requests, hasLength(2));
    expect(requests.first.url.queryParameters['spaces'], 'appDataFolder');
    expect(requests.last.method, 'PATCH');
    expect(requests.last.url.path, contains('/existing-backup'));
  });

  test('downloadBackup returns latest AppData content', () async {
    final service = GoogleCloudBackupService(
      backupService: _FakeBackupService(exportJson: '{}'),
      httpClient: MockClient((request) async {
        if (request.url.queryParameters['spaces'] == 'appDataFolder') {
          return http.Response(
            jsonEncode({
              'files': [
                {
                  'id': 'backup-1',
                  'modifiedTime': '2026-08-13T14:00:00.000Z',
                  'size': '42',
                },
              ],
            }),
            200,
          );
        }

        return http.Response('{"database":{},"sharedPreferences":{}}', 200);
      }),
      interactiveSignIn: () async => buildSession(),
      silentSignIn: () async => buildSession(),
      canAccessScopes: (_) async => true,
      requestScopes: (_) async => true,
    );

    final restoreData = await service.downloadBackup();

    expect(restoreData.rawJson, '{"database":{},"sharedPreferences":{}}');
    expect(restoreData.info.hasBackup, isTrue);
    expect(restoreData.info.backupSizeBytes, 42);
    expect(restoreData.info.user?.email, 'drive@example.com');
  });

  test('restoreBackupData delegates to backup service importer', () async {
    final backupService = _FakeBackupService(exportJson: '{}');
    final service = GoogleCloudBackupService(
      backupService: backupService,
      httpClient: MockClient((request) async => http.Response('{}', 200)),
      interactiveSignIn: () async => buildSession(),
      silentSignIn: () async => buildSession(),
      canAccessScopes: (_) async => true,
      requestScopes: (_) async => true,
    );

    await service.restoreBackupData('{"database":{},"sharedPreferences":{}}');

    expect(
      backupService.importedJson,
      '{"database":{},"sharedPreferences":{}}',
    );
  });

  test('signIn surfaces real exception message', () async {
    final service = GoogleCloudBackupService(
      backupService: _FakeBackupService(exportJson: '{}'),
      httpClient: MockClient((request) async => http.Response('{}', 200)),
      interactiveSignIn: () async {
        throw Exception('drive scope consent failed');
      },
      silentSignIn: () async => null,
      canAccessScopes: (_) async => true,
      requestScopes: (_) async => true,
    );

    await expectLater(
      service.signIn(),
      throwsA(
        isA<CloudBackupException>().having(
          (e) => e.message,
          'message',
          contains('drive scope consent failed'),
        ),
      ),
    );
  });
}
