class Fund {
  final String code;
  final String name;
  final String category;
  final double currentPrice;
  final double? previousClose;
  final double return1Y;
  final double realReturn1Y;
  final int riskScore;
  final double sharpe90;

  Fund({
    required this.code,
    required this.name,
    required this.category,
    required this.currentPrice,
    this.previousClose,
    required this.return1Y,
    required this.realReturn1Y,
    required this.riskScore,
    required this.sharpe90,
  });

  factory Fund.fromJson(Map<String, dynamic> json, String code) {
    return Fund(
      code: code,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      previousClose: _toDouble(json['previous_close'] ?? json['previousClose']),
      return1Y: (json['return_1y'] as num?)?.toDouble() ?? 0.0,
      realReturn1Y: (json['real_return_1y'] as num?)?.toDouble() ?? 0.0,
      riskScore: int.tryParse(json['risk_score']?.toString() ?? '0') ?? 0,
      sharpe90: (json['sharpe_90'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fund && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
