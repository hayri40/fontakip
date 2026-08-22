import 'user_account.dart';

class AuthState {
  final bool isSignedIn;
  final UserAccount? user;
  final String provider;
  final DateTime? updatedAt;

  const AuthState({
    required this.isSignedIn,
    this.user,
    this.provider = 'google',
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'isSignedIn': isSignedIn,
      'user': user?.toJson(),
      'provider': provider,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthState(
      isSignedIn: json['isSignedIn'] == true,
      user: userJson is Map<String, dynamic>
          ? UserAccount.fromJson(userJson)
          : null,
      provider: (json['provider'] ?? 'google').toString(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
