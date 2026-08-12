class Holding {
  final String fundCode;
  final double quantity;
  final double averageCost;

  final double currentPrice;
  final double currentValue;
  final double costValue;
  final double profitLoss;
  final double profitLossPercent;

  final double portfolioSharePercent;

  const Holding({
    required this.fundCode,
    required this.quantity,
    required this.averageCost,

    required this.currentPrice,
    required this.currentValue,
    required this.costValue,
    required this.profitLoss,
    required this.profitLossPercent,

    required this.portfolioSharePercent,
  });
}