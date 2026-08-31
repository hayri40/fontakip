import '../services/fonoloji_service.dart';
import '../models/holding.dart';
import '../features/transactions/data/transaction_repository.dart';
import '../features/transactions/models/transaction.dart';
import '../features/transactions/models/transaction_type.dart';

class PortfolioService {
  final _repository = TransactionRepository();
  final _fonoloji = FonolojiService();

  // Simple in-memory cache
  static List<Holding>? _cachedHoldings;
  static DateTime? _lastUpdateTime;

  List<Holding>? get cachedHoldings => _cachedHoldings;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  Future<List<Holding>> getHoldings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHoldings != null) {
      return _cachedHoldings!;
    }

    final transactions = await _repository.getAll();

    final Map<String, List<Transaction>> grouped = {};

    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.fundCode, () => []);

      grouped[transaction.fundCode]!.add(transaction);
    }

    final List<Holding> tempHoldings = [];

    for (final entry in grouped.entries) {
      final fundCode = entry.key;
      final items = entry.value;

      double totalBuyQuantity = 0;
      double totalBuyCost = 0;
      double totalSellQuantity = 0;

      for (final trx in items) {
        if (trx.type == TransactionType.buy) {
          totalBuyQuantity += trx.quantity;
          totalBuyCost += trx.quantity * trx.unitPrice;
        } else {
          totalSellQuantity += trx.quantity;
        }
      }

      final netQuantity = totalBuyQuantity - totalSellQuantity;

      if (netQuantity <= 0) {
        continue;
      }

      final averageCost = totalBuyCost / totalBuyQuantity;

      final costValue = netQuantity * averageCost;

      final fund = await _fonoloji.getFund(fundCode);

      final currentPrice = fund.currentPrice;
      final previousClose = fund.previousClose ?? currentPrice;

      final currentValue = netQuantity * currentPrice;

      final profitLoss = currentValue - costValue;

      final double profitLossPercent = costValue == 0
          ? 0.0
          : ((profitLoss / costValue) * 100);

      final dailyChangePercent = previousClose == 0
          ? 0.0
          : ((currentPrice - previousClose) / previousClose) * 100;
      final dailyChangeValue = (currentPrice - previousClose) * netQuantity;

      tempHoldings.add(
        Holding(
          fundCode: fundCode,
          quantity: netQuantity,
          averageCost: averageCost,

          currentPrice: currentPrice,
          currentValue: currentValue,
          costValue: costValue,
          profitLoss: profitLoss,
          profitLossPercent: profitLossPercent,

          portfolioSharePercent: 0,
          dailyChangePercent: dailyChangePercent,
          dailyChangeValue: dailyChangeValue,
        ),
      );
    }

    final totalPortfolioValue = tempHoldings.fold(
      0.0,
      (sum, item) => sum + item.currentValue,
    );

    final results = tempHoldings.map((holding) {
      final sharePercent = totalPortfolioValue == 0
          ? 0.0
          : (holding.currentValue / totalPortfolioValue) * 100;

      return Holding(
        fundCode: holding.fundCode,
        quantity: holding.quantity,
        averageCost: holding.averageCost,

        currentPrice: holding.currentPrice,
        currentValue: holding.currentValue,
        costValue: holding.costValue,
        profitLoss: holding.profitLoss,
        profitLossPercent: holding.profitLossPercent,

        portfolioSharePercent: sharePercent,
        dailyChangePercent: holding.dailyChangePercent,
        dailyChangeValue: holding.dailyChangeValue,
      );
    }).toList();

    _cachedHoldings = results;
    _lastUpdateTime = DateTime.now();

    return results;
  }

  void clearCache() {
    _cachedHoldings = null;
    _lastUpdateTime = null;
  }
}
