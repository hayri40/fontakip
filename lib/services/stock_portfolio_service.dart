import '../features/transactions/data/stock_transaction_repository.dart';
import '../features/transactions/models/stock_transaction.dart';
import '../features/transactions/models/transaction_type.dart';
import '../models/stock_holding.dart';
import 'stock_service.dart';

class StockPortfolioService {
  final _repository = StockTransactionRepository();
  final _stockService = StockService();

  // Simple in-memory cache
  static List<StockHolding>? _cachedHoldings;
  static DateTime? _lastUpdateTime;

  List<StockHolding>? get cachedHoldings => _cachedHoldings;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  Future<List<StockHolding>> getHoldings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHoldings != null) {
      return _cachedHoldings!;
    }

    final transactions = await _repository.getAll();

    final Map<String, List<StockTransaction>> grouped = {};

    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.stockSymbol, () => []);

      grouped[transaction.stockSymbol]!.add(transaction);
    }

    final List<StockHolding> holdings = [];

    for (final entry in grouped.entries) {
      final symbol = entry.key;
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

      if (netQuantity <= 0 || totalBuyQuantity <= 0) {
        continue;
      }

      final averageCost = totalBuyCost / totalBuyQuantity;
      final costValue = netQuantity * averageCost;

      final stock = await _stockService.getStockDetail(symbol);
      final currentPrice = stock.currentPrice ?? 0.0;
      final previousClose = stock.previousClose ?? currentPrice;
      final currentValue = netQuantity * currentPrice;
      final profitLoss = currentValue - costValue;
      final profitLossPercent = costValue == 0
          ? 0.0
          : ((profitLoss / costValue) * 100);
      final dailyChangePercent = previousClose == 0
          ? 0.0
          : ((currentPrice - previousClose) / previousClose) * 100;
      final dailyChangeValue = (currentPrice - previousClose) * netQuantity;

      holdings.add(
        StockHolding(
          symbol: symbol,
          totalQuantity: netQuantity,
          averageCost: averageCost,
          costValue: costValue,
          currentPrice: currentPrice,
          currentValue: currentValue,
          profitLoss: profitLoss,
          profitLossPercent: profitLossPercent,
          dailyChangePercent: dailyChangePercent,
          dailyChangeValue: dailyChangeValue,
        ),
      );
    }

    holdings.sort((a, b) => b.costValue.compareTo(a.costValue));
    
    _cachedHoldings = holdings;
    _lastUpdateTime = DateTime.now();
    
    return holdings;
  }

  void clearCache() {
    _cachedHoldings = null;
    _lastUpdateTime = null;
  }
}
