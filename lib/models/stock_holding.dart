class StockHolding {
  final String symbol;
  final double totalQuantity;
  final double averageCost;
  final double costValue;
  final double currentPrice;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercent;
  final double dailyChangePercent;
  final double dailyChangeValue;

  const StockHolding({
    required this.symbol,
    required this.totalQuantity,
    required this.averageCost,
    required this.costValue,
    required this.currentPrice,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
    this.dailyChangePercent = 0.0,
    this.dailyChangeValue = 0.0,
  });
}
