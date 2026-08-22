class Stock {
  final String symbol;
  final String name;
  final String sector;

  final double? currentPrice;
  final double? previousClose;
  final double? marketCap;
  final double? peRatio;
  final double? eps;
  final double? dayHigh;
  final double? dayLow;
  final String? priceUnavailableMessage;

  const Stock({
    required this.symbol,
    required this.name,
    required this.sector,

    this.currentPrice,
    this.previousClose,
    this.marketCap,
    this.peRatio,
    this.eps,
    this.dayHigh,
    this.dayLow,
    this.priceUnavailableMessage,
  });

  Stock copyWith({
    String? symbol,
    String? name,
    String? sector,
    double? currentPrice,
    double? previousClose,
    double? marketCap,
    double? peRatio,
    double? eps,
    double? dayHigh,
    double? dayLow,
    String? priceUnavailableMessage,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClose: previousClose ?? this.previousClose,
      marketCap: marketCap ?? this.marketCap,
      peRatio: peRatio ?? this.peRatio,
      eps: eps ?? this.eps,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      priceUnavailableMessage:
          priceUnavailableMessage ?? this.priceUnavailableMessage,
    );
  }

  factory Stock.fromJson(
      Map<String, dynamic> json,
      ) {
    final symbol = (json['symbol'] ?? '').toString();
    final normalizedSymbol = symbol.endsWith('.IS')
        ? symbol.replaceAll('.IS', '')
        : symbol;

    return Stock(
      symbol: normalizedSymbol,
      name: (json['name'] ?? json['shortName'] ?? json['longName'] ?? '').toString(),
      sector: (json['sector'] ?? 'BIST').toString(),

      currentPrice: _toDouble(json['current_price'] ?? json['regularMarketPrice']),
      previousClose: _toDouble(
        json['previous_close'] ?? json['regularMarketPreviousClose'],
      ),

      marketCap: _toDouble(json['market_cap'] ?? json['marketCap']),

      peRatio: _toDouble(json['pe_ratio'] ?? json['trailingPE']),

      eps: _toDouble(json['eps']),

      dayHigh: _toDouble(json['day_high'] ?? json['regularMarketDayHigh']),

      dayLow: _toDouble(json['day_low'] ?? json['regularMarketDayLow']),

      priceUnavailableMessage:
          (json['price_unavailable_message'] ?? json['priceUnavailableMessage'])
              ?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}