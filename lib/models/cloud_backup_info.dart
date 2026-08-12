import 'user_account.dart';

class CloudBackupInfo {
  final String provider;
  final bool isSignedIn;
  final UserAccount? user;
  final DateTime? lastUpdatedAt;

  const CloudBackupInfo({
    required this.provider,
    required this.isSignedIn,
    this.user,
    this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'isSignedIn': isSignedIn,
      'user': user?.toJson(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  factory CloudBackupInfo.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return CloudBackupInfo(
      provider: (json['provider'] ?? 'google').toString(),
      isSignedIn: json['isSignedIn'] == true,
      user: userJson is Map<String, dynamic>
          ? UserAccount.fromJson(userJson)
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] is String
          ? DateTime.tryParse(json['lastUpdatedAt'] as String)
          : null,
    );
  }
}
