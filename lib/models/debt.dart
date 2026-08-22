class Debt {
  final String id;
  final String description;
  final double amount;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  Debt copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
