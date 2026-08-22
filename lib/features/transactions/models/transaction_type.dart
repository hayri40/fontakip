enum TransactionType {
  buy,
  sell;

  String get label {
    switch (this) {
      case TransactionType.buy:
        return 'Alış';
      case TransactionType.sell:
        return 'Satış';
    }
  }

  String get dbValue {
    switch (this) {
      case TransactionType.buy:
        return 'buy';
      case TransactionType.sell:
        return 'sell';
    }
  }

  static TransactionType fromDbValue(String value) {
    switch (value) {
      case 'sell':
        return TransactionType.sell;
      case 'buy':
      default:
        return TransactionType.buy;
    }
  }
}
