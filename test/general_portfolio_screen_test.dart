import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fontakip/models/holding.dart';
import 'package:fontakip/models/debt.dart';
import 'package:fontakip/models/stock_holding.dart';
import 'package:fontakip/screens/general_portfolio_screen.dart';
import 'package:fontakip/features/debts/data/debt_repository.dart';
import 'package:fontakip/services/portfolio_service.dart';
import 'package:fontakip/services/stock_portfolio_service.dart';

class _FakePortfolioService extends PortfolioService {
  @override
  Future<List<Holding>> getHoldings({bool forceRefresh = false}) async {
    return const [
      Holding(
        fundCode: 'KLU',
        quantity: 10,
        averageCost: 100,
        currentPrice: 120,
        currentValue: 1200,
        costValue: 1000,
        profitLoss: 200,
        profitLossPercent: 20,
        portfolioSharePercent: 60,
      ),
    ];
  }
}

class _FakeStockPortfolioService extends StockPortfolioService {
  @override
  Future<List<StockHolding>> getHoldings({bool forceRefresh = false}) async {
    return const [
      StockHolding(
        symbol: 'THYAO',
        totalQuantity: 5,
        averageCost: 200,
        costValue: 1000,
        currentPrice: 220,
        currentValue: 1100,
        profitLoss: 100,
        profitLossPercent: 10,
      ),
    ];
  }
}

class _FakeDebtRepository implements DebtRepository {
  @override
  Future<Debt> add({
    required String description,
    required double amount,
  }) async {
    return Debt(
      id: '1',
      description: description,
      amount: amount,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Debt>> getAll() async {
    return [
      Debt(
        id: 'd1',
        description: 'Kredi kartı',
        amount: 500,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ];
  }
}

void main() {
  testWidgets('shows combined portfolio totals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralPortfolioScreen(
          portfolioService: _FakePortfolioService(),
          stockPortfolioService: _FakeStockPortfolioService(),
          debtRepository: _FakeDebtRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('🏠 Toplam Portföyüm'), findsOneWidget);
    expect(find.text('₺2.300,00'), findsOneWidget);
    expect(find.text('Maliyet: ₺2.000,00'), findsOneWidget);
    expect(find.text('+₺300,00 (%15,00)'), findsOneWidget);
    expect(find.text('Varlıklarım'), findsOneWidget);
    expect(find.text('Borçlarım'), findsOneWidget);
  });
}
