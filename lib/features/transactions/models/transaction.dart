import 'transaction_type.dart';

class Transaction {
  final String id;
  final String fundCode;
  final DateTime date;
  final TransactionType type;
  final double quantity;
  final double unitPrice;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.fundCode,
    required this.date,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
  });

  double get totalAmount => quantity * unitPrice;

  Transaction copyWith({
    String? id,
    String? fundCode,
    DateTime? date,
    TransactionType? type,
    double? quantity,
    double? unitPrice,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      fundCode: fundCode ?? this.fundCode,
      date: date ?? this.date,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fund_code': fundCode,
      'date': date.millisecondsSinceEpoch,
      'type': type.dbValue,
      'quantity': quantity,
      'unit_price': unitPrice,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      fundCode: map['fund_code'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: TransactionType.fromDbValue(map['type'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
