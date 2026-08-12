import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fontakip/features/debts/data/debt_repository.dart';
import 'package:fontakip/models/debt.dart';
import 'package:fontakip/models/holding.dart';
import 'package:fontakip/models/stock_holding.dart';
import 'package:fontakip/screens/compound_return_calculator_screen.dart';
import 'package:fontakip/screens/global_market_hours_screen.dart';
import 'package:fontakip/screens/investment_allocation_planner_screen.dart';
import 'package:fontakip/screens/notes_screen.dart';
import 'package:fontakip/screens/performance_tracking_screen.dart';
import 'package:fontakip/screens/portfolio_balancer_screen.dart';
import 'package:fontakip/screens/tools_screen.dart';
import 'package:fontakip/services/portfolio_service.dart';
import 'package:fontakip/services/stock_portfolio_service.dart';

class _FakePortfolioService extends PortfolioService {
  @override
  Future<List<Holding>> getHoldings() async {
    return const [
      Holding(
        fundCode: 'KTJ',
        quantity: 10,
        averageCost: 100,
        currentPrice: 120,
        currentValue: 1200,
        costValue: 1000,
        profitLoss: 200,
        profitLossPercent: 20,
        portfolioSharePercent: 60,
      ),
      Holding(
        fundCode: 'KLU',
        quantity: 10,
        averageCost: 80,
        currentPrice: 90,
        currentValue: 800,
        costValue: 700,
        profitLoss: 100,
        profitLossPercent: 14.29,
        portfolioSharePercent: 40,
      ),
      Holding(
        fundCode: 'KNJ',
        quantity: 10,
        averageCost: 50,
        currentPrice: 60,
        currentValue: 600,
        costValue: 500,
        profitLoss: 100,
        profitLossPercent: 20,
        portfolioSharePercent: 30,
      ),
    ];
  }
}

class _FakeStockPortfolioService extends StockPortfolioService {
  @override
  Future<List<StockHolding>> getHoldings() async {
    return const [
      StockHolding(
        symbol: 'THYAO',
        totalQuantity: 5,
        averageCost: 200,
        costValue: 1000,
        currentPrice: 220,
        currentValue: 1000,
        profitLoss: 0,
        profitLossPercent: 0,
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
  Future<List<Debt>> getAll() async => const [];
}

class _SequencedPortfolioService extends PortfolioService {
  _SequencedPortfolioService(this.values);

  final List<double> values;
  int _index = 0;

  @override
  Future<List<Holding>> getHoldings() async {
    final selectedIndex = _index >= values.length ? values.length - 1 : _index;
    final value = values[selectedIndex];
    _index++;
    return [
      Holding(
        fundCode: 'SIM',
        quantity: 1,
        averageCost: value,
        currentPrice: value,
        currentValue: value,
        costValue: value,
        profitLoss: 0,
        profitLossPercent: 0,
        portfolioSharePercent: 100,
      ),
    ];
  }
}

class _EmptyStockPortfolioService extends StockPortfolioService {
  @override
  Future<List<StockHolding>> getHoldings() async => const [];
}

void main() {
  testWidgets('shows tool list cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));

    expect(find.text('Forex Seans Rehberi'), findsOneWidget);
    expect(find.text('Yatırım Dağıtım Planlayıcı'), findsOneWidget);
    expect(find.text('Portföy Dengeleyici'), findsOneWidget);
    expect(find.text('Bileşik Getiri Hesaplayıcı'), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('Performans Takibi'), findsOneWidget);
  });

  testWidgets('global market hours screen renders core sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GlobalMarketHoursScreen()));
    await tester.pump();

    expect(find.text('Yerel Saat'), findsOneWidget);
    expect(find.text('Forex Durumu'), findsOneWidget);
    expect(find.text('Şu An Aktif'), findsOneWidget);
    expect(find.text('Bir Sonraki Seans'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Seans Çakışmaları'), findsOneWidget);
    expect(find.text('Volatilite'), findsOneWidget);
  });

  testWidgets('investment planner calculates allocations', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: InvestmentAllocationPlannerScreen()),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).at(0), '10000');
    await tester.enterText(find.byType(TextField).at(1), '40');
    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.enterText(find.byType(TextField).at(3), '10');
    await tester.pump();

    expect(find.text('Fon: ₺4.000,00'), findsOneWidget);
    expect(find.text('Hisse: ₺5.000,00'), findsOneWidget);
    expect(find.text('FX: ₺1.000,00'), findsOneWidget);
    expect(find.text('Toplam yüzde: %100,00'), findsOneWidget);
  });

  testWidgets(
    'investment planner fund tab starts empty and shows result after valid input',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(home: InvestmentAllocationPlannerScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Fon'));
      await tester.pumpAndSettle();

      expect(find.text('Henüz fon eklenmedi.'), findsOneWidget);
      expect(find.text('➕ Fon Satırı Ekle'), findsOneWidget);
      expect(find.text('KTJ'), findsNothing);
      expect(find.text('KNJ'), findsNothing);
      expect(find.text('KLU'), findsNothing);
      expect(find.text('Sonuç'), findsNothing);

      await tester.tap(find.text('➕ Fon Satırı Ekle'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), '10000');
      await tester.enterText(find.byType(TextField).at(1), 'AAA');
      await tester.enterText(find.byType(TextField).at(2), '100');
      await tester.pump();

      expect(find.text('Toplam yüzde: %100,00'), findsOneWidget);
      expect(find.text('Sonuç'), findsOneWidget);
      expect(find.text('AAA: ₺10.000,00'), findsOneWidget);
    },
  );

  testWidgets('portfolio balancer shows target fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioBalancerScreen(
          portfolioService: _FakePortfolioService(),
          stockPortfolioService: _FakeStockPortfolioService(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Portföy Dengeleyici'), findsOneWidget);
    expect(find.text('Genel Portföy'), findsOneWidget);
    expect(find.text('Fon Dağılımı'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '40000');
    await tester.enterText(find.byType(TextField).at(1), '40');
    await tester.enterText(find.byType(TextField).at(2), '60');
    await tester.enterText(find.byType(TextField).at(3), '0');
    await tester.pump();

    expect(find.text('Hedef dağılıma yaklaşmak için'), findsOneWidget);
    expect(find.text('₺14.840,00'), findsOneWidget);
    expect(find.text('₺25.160,00'), findsOneWidget);

    await tester.tap(find.text('Fon Dağılımı'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '20000');
    await tester.enterText(find.byType(TextField).at(1), 'KTJ');
    await tester.enterText(find.byType(TextField).at(2), '40');
    await tester.enterText(find.byType(TextField).at(3), 'KLU');
    await tester.enterText(find.byType(TextField).at(4), '30');
    await tester.enterText(find.byType(TextField).at(5), 'KNJ');
    await tester.enterText(find.byType(TextField).at(6), '30');
    await tester.pump();

    expect(find.text('KTJ'), findsWidgets);
    expect(find.text('KLU'), findsWidgets);
    expect(find.text('KNJ'), findsWidgets);
    expect(find.text('Toplam yüzde: %100,00'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('₺7.840,00'), findsOneWidget);
    expect(find.text('₺5.980,00'), findsOneWidget);
    expect(find.text('₺6.180,00'), findsOneWidget);
  });

  testWidgets('fund rows are user managed and persisted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioBalancerScreen(
          portfolioService: _FakePortfolioService(),
          stockPortfolioService: _FakeStockPortfolioService(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Fon Dağılımı'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '20000');

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.delete_outline).at(0));
      await tester.pump();
    }

    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.text('Fon Ekle'));
      await tester.tap(find.text('Fon Ekle'), warnIfMissed: false);
      await tester.pump();
    }

    await tester.enterText(find.byType(TextField).at(1), 'KTJ');
    await tester.enterText(find.byType(TextField).at(2), '40');
    await tester.enterText(find.byType(TextField).at(3), 'KLU');
    await tester.enterText(find.byType(TextField).at(4), '25');
    await tester.enterText(find.byType(TextField).at(5), 'Altın');
    await tester.enterText(find.byType(TextField).at(6), '15');
    await tester.enterText(find.byType(TextField).at(7), 'Gümüş');
    await tester.enterText(find.byType(TextField).at(8), '20');
    await tester.pump();

    expect(find.text('KTJ'), findsWidgets);
    expect(find.text('KLU'), findsWidgets);
    expect(find.text('Altın'), findsWidgets);
    expect(find.text('Gümüş'), findsWidgets);
    expect(find.text('Toplam yüzde: %100,00'), findsOneWidget);
    expect(find.text('₺7.611,65'), findsOneWidget);
    expect(find.text('₺4.708,74'), findsOneWidget);
    expect(find.text('₺3.291,26'), findsOneWidget);
    expect(find.text('₺4.388,35'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioBalancerScreen(
          portfolioService: _FakePortfolioService(),
          stockPortfolioService: _FakeStockPortfolioService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Fon Dağılımı'));
    await tester.pumpAndSettle();

    expect(find.text('KTJ'), findsWidgets);
    expect(find.text('Altın'), findsWidgets);
    expect(find.text('Gümüş'), findsWidgets);
  });

  testWidgets('compound calculator computes and persists values', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: CompoundReturnCalculatorScreen()),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).at(0), '100000');
    await tester.enterText(find.byType(TextField).at(1), '10000');
    await tester.enterText(find.byType(TextField).at(2), '3');
    await tester.enterText(find.byType(TextField).at(3), '5');
    await tester.pump();

    expect(find.text('≈ %42,58 yıllık bileşik karşılığı'), findsOneWidget);

    await tester.tap(find.text('Yıllık'));
    await tester.pump();
    expect(find.text('≈ %0,25 aylık karşılığı'), findsOneWidget);

    await tester.tap(find.text('Aylık'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(2), '0');
    await tester.pump();

    expect(find.text('₺700.000,00'), findsNWidgets(2));
    expect(find.text('₺0,00'), findsOneWidget);
    expect(find.text('Toplam Getiri: %0,00'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('Yıl 1'), findsOneWidget);
    expect(find.text('Yıl 5'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: CompoundReturnCalculatorScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final textFields = find.byType(TextField);
    expect(
      (tester.widget<TextField>(textFields.at(0)).controller?.text ?? ''),
      '100000',
    );
    expect(
      (tester.widget<TextField>(textFields.at(1)).controller?.text ?? ''),
      '10000',
    );
    expect(
      (tester.widget<TextField>(textFields.at(2)).controller?.text ?? ''),
      '0',
    );
    expect(
      (tester.widget<TextField>(textFields.at(3)).controller?.text ?? ''),
      '5',
    );
  });

  testWidgets('performance tracker records and stats work with confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final portfolioService = _SequencedPortfolioService([530000, 540000]);
    var nowCall = 0;
    final dates = [DateTime(2026, 9, 1), DateTime(2026, 10, 1)];

    await tester.pumpWidget(
      MaterialApp(
        home: PerformanceTrackingScreen(
          portfolioService: portfolioService,
          stockPortfolioService: _EmptyStockPortfolioService(),
          nowProvider: () {
            final idx = nowCall >= dates.length ? dates.length - 1 : nowCall;
            nowCall++;
            return dates[idx];
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).first, '3');
    await tester.pump();

    await tester.tap(find.text('➕ Yeni Kayıt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('➕ Yeni Kayıt'));
    await tester.pumpAndSettle();

    expect(find.text('01.09.2026'), findsOneWidget);
    expect(find.text('01.10.2026'), findsOneWidget);
    expect(find.text('%1,89'), findsWidgets);
    expect(find.text('%3,00'), findsWidgets);
    expect(find.text('-%1,11'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Kayıt Sayısı'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Hedef Üstü Kayıt'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('Hedef Altı Kayıt'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('%1,89'), findsWidgets);
    expect(find.text('%3,00'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🗑 Son Kaydı Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Son Kaydı Sil'), findsOneWidget);
    expect(find.text('Hayır'), findsOneWidget);
    expect(find.text('Evet, Sil'), findsOneWidget);

    await tester.tap(find.text('Hayır'));
    await tester.pumpAndSettle();
    expect(find.text('01.10.2026'), findsOneWidget);

    await tester.tap(find.text('🗑 Son Kaydı Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evet, Sil'));
    await tester.pumpAndSettle();
    expect(find.text('01.10.2026'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: PerformanceTrackingScreen(
          portfolioService: _FakePortfolioService(),
          stockPortfolioService: _FakeStockPortfolioService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      '3',
    );
    expect(find.text('01.09.2026'), findsOneWidget);
  });

  testWidgets('notes tool supports add edit delete and persistence', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: NotesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Henüz not yok.'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Plan');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Aylık alım planı',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Aylık alım planı'), findsNothing);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Aylık alım planı'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Plan Güncel');
    await tester.enterText(find.byType(TextFormField).at(1), 'Revize içerik');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Güncel'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: NotesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Plan Güncel'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evet, Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz not yok.'), findsOneWidget);
  });
}
