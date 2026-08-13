import 'user_account.dart';

class CloudBackupInfo {
  final String provider;
  final bool isSignedIn;
  final bool hasBackup;
  final UserAccount? user;
  final DateTime? lastUpdatedAt;
  final int? backupSizeBytes;

  const CloudBackupInfo({
    required this.provider,
    required this.isSignedIn,
    this.hasBackup = false,
    this.user,
    this.lastUpdatedAt,
    this.backupSizeBytes,
  });

  CloudBackupInfo copyWith({
    String? provider,
    bool? isSignedIn,
    bool? hasBackup,
    UserAccount? user,
    bool clearUser = false,
    DateTime? lastUpdatedAt,
    bool clearLastUpdatedAt = false,
    int? backupSizeBytes,
    bool clearBackupSizeBytes = false,
  }) {
    return CloudBackupInfo(
      provider: provider ?? this.provider,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      hasBackup: hasBackup ?? this.hasBackup,
      user: clearUser ? null : (user ?? this.user),
      lastUpdatedAt: clearLastUpdatedAt
          ? null
          : (lastUpdatedAt ?? this.lastUpdatedAt),
      backupSizeBytes: clearBackupSizeBytes
          ? null
          : (backupSizeBytes ?? this.backupSizeBytes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'isSignedIn': isSignedIn,
      'hasBackup': hasBackup,
      'user': user?.toJson(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      'backupSizeBytes': backupSizeBytes,
    };
  }

  factory CloudBackupInfo.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return CloudBackupInfo(
      provider: (json['provider'] ?? 'google').toString(),
      isSignedIn: json['isSignedIn'] == true,
      hasBackup: json['hasBackup'] == true,
      user: userJson is Map<String, dynamic>
          ? UserAccount.fromJson(userJson)
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] is String
          ? DateTime.tryParse(json['lastUpdatedAt'] as String)
          : null,
      backupSizeBytes: json['backupSizeBytes'] is int
          ? json['backupSizeBytes'] as int
          : int.tryParse('${json['backupSizeBytes'] ?? ''}'),
    );
  }
}

class CloudRestoreData {
  final String rawJson;
  final CloudBackupInfo info;

  const CloudRestoreData({
    required this.rawJson,
    required this.info,
  });
}
