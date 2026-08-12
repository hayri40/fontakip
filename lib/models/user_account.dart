class UserAccount {
  final String id;
  final String email;
  final String provider;
  final DateTime createdAt;
  final String? displayName;
  final String? photoUrl;

  const UserAccount({
    required this.id,
    required this.email,
    required this.provider,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'];
    return UserAccount(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      provider: (json['provider'] ?? 'google').toString(),
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
          : DateTime.now(),
      displayName: json['displayName'] == null
          ? null
          : (json['displayName'] ?? '').toString(),
      photoUrl: json['photoUrl'] == null
          ? null
          : (json['photoUrl'] ?? '').toString(),
    );
  }
}
