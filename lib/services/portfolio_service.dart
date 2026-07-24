import '../models/holding.dart';
import '../features/transactions/data/transaction_repository.dart';
import '../features/transactions/models/transaction.dart';
import '../features/transactions/models/transaction_type.dart';

class PortfolioService {
  final _repository = TransactionRepository();

  Future<List<Holding>> getHoldings() async {
    final transactions = await _repository.getAll();

    final Map<String, List<Transaction>> grouped = {};

    for (final transaction in transactions) {
      grouped.putIfAbsent(
        transaction.fundCode,
            () => [],
      );

      grouped[transaction.fundCode]!.add(transaction);
    }

    final List<Holding> holdings = [];

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

      final netQuantity =
          totalBuyQuantity - totalSellQuantity;

      if (netQuantity <= 0) {
        continue;
      }

      final averageCost =
          totalBuyCost / totalBuyQuantity;

      holdings.add(
        Holding(
          fundCode: fundCode,
          quantity: netQuantity,
          averageCost: averageCost,
        ),
      );
    }

    return holdings;
  }
}