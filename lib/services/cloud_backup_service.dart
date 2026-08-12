import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_state.dart';
import '../models/user_account.dart';

abstract class CloudBackupService {
  Future<void> signIn({String? email});
  Future<void> signOut();
  Future<void> uploadBackup();
  Future<void> restoreBackup();
  Future<AuthState> getAuthState();
  bool get isSignedIn;
}

class GoogleCloudBackupService implements CloudBackupService {
  static const String _storageKey = 'cloud_backup_auth_state';

  AuthState? _cachedState;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  GoogleCloudBackupService();

  @override
  bool get isSignedIn => _cachedState?.isSignedIn ?? false;

  @override
  Future<void> signIn({String? email}) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _cachedState = const AuthState(isSignedIn: false, provider: 'google');
        return;
      }

      final now = DateTime.now();
      final state = AuthState(
        isSignedIn: true,
        provider: 'google',
        user: UserAccount(
          id: account.id,
          email: account.email,
          provider: 'google',
          createdAt: now,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        ),
        updatedAt: now,
      );

      _cachedState = state;
      final prefs = await _prefsFuture;
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (_) {
      _cachedState = const AuthState(isSignedIn: false, provider: 'google');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _cachedState = const AuthState(isSignedIn: false, provider: 'google');
    final prefs = await _prefsFuture;
    await prefs.remove(_storageKey);
  }

  @override
  Future<void> uploadBackup() async {
    return;
  }

  @override
  Future<void> restoreBackup() async {
    return;
  }

  @override
  Future<AuthState> getAuthState() async {
    if (_cachedState != null) {
      return _cachedState!;
    }

    final prefs = await _prefsFuture;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cachedState = const AuthState(isSignedIn: false, provider: 'google');
      return _cachedState!;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cachedState = AuthState.fromJson(decoded);
        return _cachedState!;
      }
    } catch (_) {}

    _cachedState = const AuthState(isSignedIn: false, provider: 'google');
    return _cachedState!;
  }
}
