import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_state.dart';
import '../models/cloud_backup_info.dart';
import '../models/user_account.dart';
import 'backup_service.dart';

abstract class CloudBackupService {
  Future<AuthState> signIn({String? email});
  Future<void> signOut();
  Future<CloudBackupInfo> uploadBackup();
  Future<CloudRestoreData> downloadBackup();
  Future<void> restoreBackupData(String rawJson);
  Future<AuthState> getAuthState();
  Future<CloudBackupInfo> getBackupInfo();
  bool get isSignedIn;
}

class CloudBackupException implements Exception {
  final String message;

  const CloudBackupException(this.message);

  @override
  String toString() => message;
}

class DriveUserSession {
  final UserAccount user;
  final Future<Map<String, String>> Function() authHeadersProvider;

  const DriveUserSession({
    required this.user,
    required this.authHeadersProvider,
  });

  Future<Map<String, String>> get authHeaders => authHeadersProvider();
}

class GoogleCloudBackupService implements CloudBackupService {
  static const String _authStorageKey = 'cloud_backup_auth_state';
  static const String _infoStorageKey = 'cloud_backup_info_state';
  static const String _provider = 'google';
  static const String _driveScope =
      'https://www.googleapis.com/auth/drive.appdata';
  static const String _backupFileName = 'fontakip_backup.json';
  static const String _driveFilesEndpoint =
      'https://www.googleapis.com/drive/v3/files';
  static const String _driveUploadEndpoint =
      'https://www.googleapis.com/upload/drive/v3/files';

  AuthState? _cachedState;
  CloudBackupInfo? _cachedBackupInfo;

  final GoogleSignIn _googleSignIn;
  final BackupService _backupService;
  final http.Client _httpClient;
  final Future<SharedPreferences> _prefsFuture;
  late final Future<DriveUserSession?> Function() _interactiveSignIn;
  late final Future<DriveUserSession?> Function() _silentSignIn;
  late final Future<void> Function() _signOutAction;

  GoogleCloudBackupService({
    GoogleSignIn? googleSignIn,
    BackupService? backupService,
    http.Client? httpClient,
    Future<SharedPreferences>? prefsFuture,
    Future<DriveUserSession?> Function()? interactiveSignIn,
    Future<DriveUserSession?> Function()? silentSignIn,
    Future<void> Function()? signOutAction,
  }) : _googleSignIn = googleSignIn ??
           GoogleSignIn(
             scopes: const [
               'email',
               'profile',
               'https://www.googleapis.com/auth/drive.appdata',
             ],
           ),
       _backupService = backupService ?? BackupService(),
       _httpClient = httpClient ?? http.Client(),
       _prefsFuture = prefsFuture ?? SharedPreferences.getInstance() {
    _interactiveSignIn = interactiveSignIn ?? _signInWithGoogle;
    _silentSignIn = silentSignIn ?? _signInSilentlyWithGoogle;
    _signOutAction = signOutAction ?? _signOutFromGoogle;
  }

  @override
  bool get isSignedIn => _cachedState?.isSignedIn ?? false;

  static DriveUserSession? _mapGoogleAccount(GoogleSignInAccount? account) {
    if (account == null) {
      return null;
    }

    final now = DateTime.now();
    return DriveUserSession(
      user: UserAccount(
        id: account.id,
        email: account.email,
        provider: _provider,
        createdAt: now,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      ),
      authHeadersProvider: () async {
        // Use dynamic to bypass static analysis error on accessToken
        final dynamic auth = await account.authentication;
        return {
          'Authorization': 'Bearer ${auth.accessToken}',
        };
      },
    );
  }

  Future<DriveUserSession?> _signInWithGoogle() async {
    developer.log('Starting Google Sign-In...', name: 'ExpertDebug');
    try {
      final account = await _googleSignIn.signIn();
      
      if (account != null) {
        developer.log('Account received: ${account.email}. Fetching Firebase auth...', name: 'ExpertDebug');
        // Use dynamic to bypass static analysis error on accessToken/idToken
        final dynamic googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        developer.log('Firebase Sign-In Success: ${userCredential.user?.uid}', name: 'ExpertDebug');
      }
      return _mapGoogleAccount(account);
    } catch (e) {
      developer.log('Error during Google Sign-In: $e', name: 'ExpertDebug');
      return null;
    }
  }

  Future<DriveUserSession?> _signInSilentlyWithGoogle() async {
    try {
      final account = await _googleSignIn.signInSilently();
      
      if (account != null) {
        // Use dynamic to bypass static analysis error on accessToken/idToken
        final dynamic googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      return _mapGoogleAccount(account);
    } catch (e) {
      developer.log('Error during silent Google Sign-In: $e', name: 'ExpertDebug');
      return null;
    }
  }

  Future<void> _signOutFromGoogle() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<AuthState> signIn({String? email}) async {
    try {
      final session = await _interactiveSignIn();
      if (session == null) {
        final state = const AuthState(isSignedIn: false, provider: _provider);
        await _persistAuthState(state);
        return state;
      }

      final state = _buildAuthState(session.user);
      await _persistAuthState(state);
      final cachedInfo = await _getCachedBackupInfo();
      await _persistBackupInfo(
        _buildSignedInInfo(
          user: session.user,
          hasBackup: cachedInfo?.hasBackup ?? false,
          lastUpdatedAt: cachedInfo?.lastUpdatedAt,
          backupSizeBytes: cachedInfo?.backupSizeBytes,
        ),
      );
      return state;
    } on SocketException {
      throw const CloudBackupException('İnternet bağlantısı bulunamadı');
    } catch (error, stackTrace) {
      developer.log(
        'CRITICAL: Google sign-in failed',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      final state = const AuthState(isSignedIn: false, provider: _provider);
      await _persistAuthState(state);
      throw CloudBackupException(_describeSignInError(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _signOutAction();
    } catch (error, stackTrace) {
      developer.log(
        'Google sign-out failed',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _cachedState = const AuthState(isSignedIn: false, provider: _provider);
    _cachedBackupInfo = const CloudBackupInfo(
      provider: _provider,
      isSignedIn: false,
    );

    final prefs = await _prefsFuture;
    await prefs.remove(_authStorageKey);
    await prefs.remove(_infoStorageKey);
  }

  @override
  Future<CloudBackupInfo> uploadBackup() async {
    final session = await _requireSession();
    final authHeaders = await _authorizedHeaders(session);
    final existing = await _findLatestBackup(authHeaders: authHeaders);
    final jsonBody = await _backupService.createBackupJson();
    final uploadedFile = await _uploadBackupFile(
      authHeaders: authHeaders,
      jsonBody: jsonBody,
      existingFileId: existing?.id,
    );

    final info = _buildSignedInInfo(
      user: session.user,
      hasBackup: true,
      lastUpdatedAt: uploadedFile.modifiedTime,
      backupSizeBytes: uploadedFile.sizeBytes ?? utf8.encode(jsonBody).length,
    );
    await _persistAuthState(_buildAuthState(session.user));
    await _persistBackupInfo(info);
    return info;
  }

  @override
  Future<CloudRestoreData> downloadBackup() async {
    final session = await _requireSession();
    final authHeaders = await _authorizedHeaders(session);
    final backupFile = await _findLatestBackup(authHeaders: authHeaders);
    if (backupFile == null) {
      throw const CloudBackupException('Bulutta kayıtlı yedek bulunamadı');
    }

    final response = await _sendAuthorizedRequest(
      method: 'GET',
      uri: Uri.parse('$_driveFilesEndpoint/${backupFile.id}?alt=media'),
      authHeaders: authHeaders,
    );
    _ensureDriveSuccess(response, operation: 'download backup');

    final info = _buildSignedInInfo(
      user: session.user,
      hasBackup: true,
      lastUpdatedAt: backupFile.modifiedTime,
      backupSizeBytes: backupFile.sizeBytes ?? response.bodyBytes.length,
    );
    await _persistAuthState(_buildAuthState(session.user));
    await _persistBackupInfo(info);

    return CloudRestoreData(rawJson: response.body, info: info);
  }

  @override
  Future<void> restoreBackupData(String rawJson) async {
    try {
      await _backupService.importBackupFromJson(rawJson);
    } on FormatException {
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'Cloud backup restore failed',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CloudBackupException(
        'Bulut yedeği geri yüklenirken bir hata oluştu',
      );
    }
  }

  @override
  Future<AuthState> getAuthState() async {
    if (_cachedState != null) {
      return _cachedState!;
    }

    try {
      final session = await _silentSignIn();
      if (session != null) {
        final state = _buildAuthState(session.user);
        await _persistAuthState(state);
        return state;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Silent sign-in failed',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final prefs = await _prefsFuture;
    final raw = prefs.getString(_authStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cachedState = const AuthState(isSignedIn: false, provider: _provider);
      return _cachedState!;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cachedState = AuthState.fromJson(decoded);
        return _cachedState!;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to decode cached auth state',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _cachedState = const AuthState(isSignedIn: false, provider: _provider);
    return _cachedState!;
  }

  @override
  Future<CloudBackupInfo> getBackupInfo() async {
    final authState = await getAuthState();
    final cachedInfo = await _getCachedBackupInfo();
    final baseInfo = _buildSignedInInfo(
      user: authState.user,
      hasBackup: cachedInfo?.hasBackup ?? false,
      lastUpdatedAt: cachedInfo?.lastUpdatedAt,
      backupSizeBytes: cachedInfo?.backupSizeBytes,
      isSignedIn: authState.isSignedIn,
    );

    if (!authState.isSignedIn) {
      final signedOutInfo = const CloudBackupInfo(
        provider: _provider,
        isSignedIn: false,
      );
      _cachedBackupInfo = signedOutInfo;
      return signedOutInfo;
    }

    try {
      final session = await _silentSignIn();
      if (session == null) {
        _cachedBackupInfo = baseInfo;
        return baseInfo;
      }

      final authHeaders = await _authorizedHeaders(session);
      final backupFile = await _findLatestBackup(authHeaders: authHeaders);
      final info = _buildSignedInInfo(
        user: session.user,
        hasBackup: backupFile != null,
        lastUpdatedAt: backupFile?.modifiedTime,
        backupSizeBytes: backupFile?.sizeBytes,
      );
      await _persistAuthState(_buildAuthState(session.user));
      await _persistBackupInfo(info);
      return info;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to refresh cloud backup info',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      _cachedBackupInfo = baseInfo;
      return baseInfo;
    }
  }

  Future<Map<String, String>> _authorizedHeaders(
    DriveUserSession session,
  ) async {
    try {
      return await session.authHeaders;
    } on SocketException {
      throw const CloudBackupException('İnternet bağlantısı bulunamadı');
    } catch (error, stackTrace) {
      developer.log(
        'Failed to get Google auth headers',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CloudBackupException('Google hesabı ile tekrar giriş yapın');
    }
  }

  Future<DriveUserSession> _requireSession() async {
    try {
      final session = await _silentSignIn() ?? await _interactiveSignIn();
      if (session == null) {
        throw const CloudBackupException('Google hesabı ile giriş yapın');
      }
      return session;
    } on CloudBackupException {
      rethrow;
    } on SocketException {
      throw const CloudBackupException('İnternet bağlantısı bulunamadı');
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve Google session',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CloudBackupException('Google hesabı ile tekrar giriş yapın');
    }
  }

  String _describeSignInError(Object error) {
    if (error is PlatformException) {
      final code = error.code.trim();
      final message = (error.message ?? '').trim();
      final details = error.details?.toString().trim() ?? '';
      final parts = <String>[
        if (code.isNotEmpty) 'code=$code',
        if (message.isNotEmpty) message,
        if (details.isNotEmpty) details,
      ];
      if (parts.isNotEmpty) {
        return 'Google ile giriş başarısız oldu (${parts.join(' | ')})';
      }
    }
    return 'Google ile giriş başarısız oldu (${error.toString()})';
  }

  AuthState _buildAuthState(UserAccount user) {
    return AuthState(
      isSignedIn: true,
      provider: _provider,
      user: user,
      updatedAt: DateTime.now(),
    );
  }

  CloudBackupInfo _buildSignedInInfo({
    UserAccount? user,
    bool hasBackup = false,
    DateTime? lastUpdatedAt,
    int? backupSizeBytes,
    bool isSignedIn = true,
  }) {
    return CloudBackupInfo(
      provider: _provider,
      isSignedIn: isSignedIn,
      hasBackup: hasBackup,
      user: user,
      lastUpdatedAt: lastUpdatedAt,
      backupSizeBytes: backupSizeBytes,
    );
  }

  Future<void> _persistAuthState(AuthState state) async {
    _cachedState = state;
    final prefs = await _prefsFuture;
    await prefs.setString(_authStorageKey, jsonEncode(state.toJson()));
  }

  Future<void> _persistBackupInfo(CloudBackupInfo info) async {
    _cachedBackupInfo = info;
    final prefs = await _prefsFuture;
    await prefs.setString(_infoStorageKey, jsonEncode(info.toJson()));
  }

  Future<CloudBackupInfo?> _getCachedBackupInfo() async {
    if (_cachedBackupInfo != null) {
      return _cachedBackupInfo;
    }

    final prefs = await _prefsFuture;
    final raw = prefs.getString(_infoStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cachedBackupInfo = CloudBackupInfo.fromJson(decoded);
        return _cachedBackupInfo;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to decode cached cloud backup info',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<_DriveBackupFile?> _findLatestBackup({
    required Map<String, String> authHeaders,
  }) async {
    final uri = Uri.parse(_driveFilesEndpoint).replace(
      queryParameters: <String, String>{
        'spaces': 'appDataFolder',
        'pageSize': '1',
        'orderBy': 'modifiedTime desc',
        'fields': 'files(id,name,modifiedTime,size)',
        'q': "name='$_backupFileName' and trashed=false",
      },
    );
    final response = await _sendAuthorizedRequest(
      method: 'GET',
      uri: uri,
      authHeaders: authHeaders,
    );
    _ensureDriveSuccess(response, operation: 'list backups');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CloudBackupException('Google Drive yanıtı okunamadı');
    }

    final files = decoded['files'];
    if (files is! List || files.isEmpty) {
      return null;
    }

    final first = files.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    return _DriveBackupFile.fromJson(first);
  }

  Future<_DriveBackupFile> _uploadBackupFile({
    required Map<String, String> authHeaders,
    required String jsonBody,
    String? existingFileId,
  }) async {
    final metadata = <String, dynamic>{
      'name': _backupFileName,
      if (existingFileId == null) 'parents': const ['appDataFolder'],
    };
    final boundary = 'fontakip-${DateTime.now().microsecondsSinceEpoch}';
    final body = utf8.encode(
      '--$boundary\r\n'
      'Content-Type: application/json; charset=UTF-8\r\n\r\n'
      '${jsonEncode(metadata)}\r\n'
      '--$boundary\r\n'
      'Content-Type: application/json; charset=UTF-8\r\n\r\n'
      '$jsonBody\r\n'
      '--$boundary--',
    );

    final uri =
        Uri.parse(
          existingFileId == null
              ? _driveUploadEndpoint
              : '$_driveUploadEndpoint/$existingFileId',
        ).replace(
          queryParameters: const <String, String>{
            'uploadType': 'multipart',
            'fields': 'id,name,modifiedTime,size',
          },
        );

    final response = await _sendAuthorizedRequest(
      method: existingFileId == null ? 'POST' : 'PATCH',
      uri: uri,
      authHeaders: authHeaders,
      headers: <String, String>{
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      bodyBytes: body,
    );
    _ensureDriveSuccess(response, operation: 'upload backup');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CloudBackupException('Google Drive yükleme yanıtı okunamadı');
    }

    return _DriveBackupFile.fromJson(decoded);
  }

  Future<http.Response> _sendAuthorizedRequest({
    required String method,
    required Uri uri,
    required Map<String, String> authHeaders,
    Map<String, String>? headers,
    List<int>? bodyBytes,
  }) async {
    try {
      final request = http.Request(method, uri);
      request.headers.addAll(authHeaders);
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (bodyBytes != null) {
        request.bodyBytes = bodyBytes;
      }

      final streamed = await _httpClient.send(request);
      return http.Response.fromStream(streamed);
    } on SocketException {
      throw const CloudBackupException('İnternet bağlantısı bulunamadı');
    } on http.ClientException catch (error, stackTrace) {
      developer.log(
        'HTTP client error for Google Drive request',
        name: 'GoogleCloudBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CloudBackupException('Google Drive bağlantısı kurulamadı');
    }
  }

  void _ensureDriveSuccess(
    http.Response response, {
    required String operation,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final errorMessage = _extractDriveErrorMessage(response.body);
    developer.log(
      'Google Drive $operation failed: ${response.statusCode} $errorMessage',
      name: 'GoogleCloudBackupService',
    );

    if (response.statusCode == 404) {
      throw const CloudBackupException('Bulutta kayıtlı yedek bulunamadı');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const CloudBackupException('Google hesabı ile tekrar giriş yapın');
    }

    throw const CloudBackupException('Google Drive işlemi başarısız oldu');
  }

  String _extractDriveErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return 'empty response body';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] != null) {
          return error['message'].toString();
        }
      }
    } catch (_) {}

    return responseBody;
  }
}

class _DriveBackupFile {
  final String id;
  final DateTime? modifiedTime;
  final int? sizeBytes;

  const _DriveBackupFile({required this.id, this.modifiedTime, this.sizeBytes});

  factory _DriveBackupFile.fromJson(Map<String, dynamic> json) {
    return _DriveBackupFile(
      id: (json['id'] ?? '').toString(),
      modifiedTime: json['modifiedTime'] is String
          ? DateTime.tryParse(json['modifiedTime'] as String)
          : null,
      sizeBytes: json['size'] is int
          ? json['size'] as int
          : int.tryParse('${json['size'] ?? ''}'),
    );
  }
}
