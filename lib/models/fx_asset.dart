enum FxAssetType { currency, commodity, crypto, other }

class FxAsset {
  final String id;
  final String name;
  final String symbol;
  final double? currentPrice;
  final double? changePercent;
  final double? dayHigh;
  final double? dayLow;
  final FxAssetType type;

  const FxAsset({
    required this.id,
    required this.name,
    required this.symbol,
    this.currentPrice,
    this.changePercent,
    this.dayHigh,
    this.dayLow,
    required this.type,
  });

  FxAsset copyWith({
    String? id,
    String? name,
    String? symbol,
    double? currentPrice,
    double? changePercent,
    double? dayHigh,
    double? dayLow,
    FxAssetType? type,
  }) {
    return FxAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      currentPrice: currentPrice ?? this.currentPrice,
      changePercent: changePercent ?? this.changePercent,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'currentPrice': currentPrice,
      'changePercent': changePercent,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'type': type.name,
    };
  }

  factory FxAsset.fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] ?? '').toString();
    final parsedType =
        FxAssetType.values.where((e) => e.name == typeName).isNotEmpty
        ? FxAssetType.values.firstWhere((e) => e.name == typeName)
        : FxAssetType.other;

    return FxAsset(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      currentPrice: _toDouble(json['currentPrice']),
      changePercent: _toDouble(json['changePercent']),
      dayHigh: _toDouble(json['dayHigh']),
      dayLow: _toDouble(json['dayLow']),
      type: parsedType,
    );
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return symbol.toLowerCase().contains(q) || name.toLowerCase().contains(q);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
