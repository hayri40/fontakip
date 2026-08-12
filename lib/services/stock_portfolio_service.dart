import '../features/transactions/data/stock_transaction_repository.dart';
import '../features/transactions/models/stock_transaction.dart';
import '../features/transactions/models/transaction_type.dart';
import '../models/stock_holding.dart';
import 'stock_service.dart';

class StockPortfolioService {
  final _repository = StockTransactionRepository();
  final _stockService = StockService();

  Future<List<StockHolding>> getHoldings() async {
    final transactions = await _repository.getAll();

    final Map<String, List<StockTransaction>> grouped = {};

    for (final transaction in transactions) {
      grouped.putIfAbsent(
        transaction.stockSymbol,
        () => [],
      );

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
      final currentValue = netQuantity * currentPrice;
      final profitLoss = currentValue - costValue;
      final profitLossPercent =
          costValue == 0 ? 0.0 : ((profitLoss / costValue) * 100);

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
        ),
      );
    }

    holdings.sort((a, b) => b.costValue.compareTo(a.costValue));
    return holdings;
  }
}
