import 'transaction_type.dart';

class StockTransaction {
  final String id;
  final String stockSymbol;
  final DateTime date;
  final TransactionType type;
  final double quantity;
  final double unitPrice;
  final DateTime createdAt;

  const StockTransaction({
    required this.id,
    required this.stockSymbol,
    required this.date,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
  });

  double get totalAmount => quantity * unitPrice;

  StockTransaction copyWith({
    String? id,
    String? stockSymbol,
    DateTime? date,
    TransactionType? type,
    double? quantity,
    double? unitPrice,
    DateTime? createdAt,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      stockSymbol: stockSymbol ?? this.stockSymbol,
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
      'stock_symbol': stockSymbol,
      'date': date.millisecondsSinceEpoch,
      'type': type.dbValue,
      'quantity': quantity,
      'unit_price': unitPrice,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] as String,
      stockSymbol: map['stock_symbol'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: TransactionType.fromDbValue(map['type'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
