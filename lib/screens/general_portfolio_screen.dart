import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';
import '../features/debts/data/debt_repository.dart';
import '../models/holding.dart';
import '../models/stock_holding.dart';
import '../services/portfolio_service.dart';
import '../services/stock_portfolio_service.dart';
import 'debt_screen.dart';

class GeneralPortfolioScreen extends StatefulWidget {
  final PortfolioService? portfolioService;
  final StockPortfolioService? stockPortfolioService;
  final DebtRepository? debtRepository;

  const GeneralPortfolioScreen({
    super.key,
    this.portfolioService,
    this.stockPortfolioService,
    this.debtRepository,
  });

  @override
  State<GeneralPortfolioScreen> createState() => _GeneralPortfolioScreenState();
}

class _GeneralPortfolioScreenState extends State<GeneralPortfolioScreen> {
  late final PortfolioService _portfolioService;
  late final StockPortfolioService _stockPortfolioService;
  late final DebtRepository _debtRepository;

  List<Holding> _fundHoldings = [];
  List<StockHolding> _stockHoldings = [];
  bool _loading = true;
  String? _fundError;
  String? _stockError;

  @override
  void initState() {
    super.initState();
    _portfolioService = widget.portfolioService ?? PortfolioService();
    _stockPortfolioService =
        widget.stockPortfolioService ?? StockPortfolioService();
    _debtRepository = widget.debtRepository ?? DebtRepository();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _loading = true;
      _fundError = null;
      _stockError = null;
    });

    List<Holding> fundHoldings = [];
    List<StockHolding> stockHoldings = [];
    String? fundError;
    String? stockError;

    try {
      fundHoldings = await _portfolioService.getHoldings();
    } catch (e) {
      fundError = 'Fon verisi alınamadı: $e';
    }

    try {
      stockHoldings = await _stockPortfolioService.getHoldings();
    } catch (e) {
      stockError = 'Hisse verisi alınamadı: $e';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _fundHoldings = fundHoldings;
      _stockHoldings = stockHoldings;
      _fundError = fundError;
      _stockError = stockError;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final fundValue = _fundHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    final fundCost = _fundHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.costValue,
    );
    final stockValue = _stockHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    final stockCost = _stockHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.costValue,
    );
    const fxValue = 0.0;
    final totalValue = fundValue + stockValue + fxValue;
    final totalCost = fundCost + stockCost;
    final totalProfitLoss = totalValue - totalCost;
    final totalProfitLossPercent =
        totalCost == 0 ? 0.0 : (totalProfitLoss / totalCost) * 100;
    final fundProfitLoss = fundValue - fundCost;
    final fundProfitLossPercent =
        fundCost == 0 ? 0.0 : (fundProfitLoss / fundCost) * 100;
    final stockProfitLoss = stockValue - stockCost;
    final stockProfitLossPercent =
        stockCost == 0 ? 0.0 : (stockProfitLoss / stockCost) * 100;

    final fundPercent = totalValue == 0 ? 0.0 : (fundValue / totalValue) * 100;
    final stockPercent = totalValue == 0 ? 0.0 : (stockValue / totalValue) * 100;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Genel Portföyüm'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Varlıklarım'),
              Tab(text: 'Borçlarım'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadPortfolio,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_fundError != null || _stockError != null) ...[
                    _buildErrorBanner(),
                    const SizedBox(height: 12),
                  ],
                  _buildHeroCard(
                    totalValue: totalValue,
                    totalCost: totalCost,
                    totalProfitLoss: totalProfitLoss,
                    totalProfitLossPercent: totalProfitLossPercent,
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownCard(
                    fundValue: fundValue,
                    fundCost: fundCost,
                    fundProfitLoss: fundProfitLoss,
                    fundProfitLossPercent: fundProfitLossPercent,
                    stockValue: stockValue,
                    stockCost: stockCost,
                    stockProfitLoss: stockProfitLoss,
                    stockProfitLossPercent: stockProfitLossPercent,
                    fxValue: fxValue,
                    fxCost: 0.0,
                    fundPercent: fundPercent,
                    stockPercent: stockPercent,
                  ),
                ],
              ),
            ),
            DebtScreen(repository: _debtRepository),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    final messages = <String>[];
    if (_fundError != null) {
      messages.add(_fundError!);
    }
    if (_stockError != null) {
      messages.add(_stockError!);
    }

    return Card(
      color: Colors.red.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          messages.join('\n'),
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required double totalValue,
    required double totalCost,
    required double totalProfitLoss,
    required double totalProfitLossPercent,
  }) {
    final isProfit = totalProfitLoss >= 0;
    final accentColor = isProfit ? Colors.green : Colors.red;

    return Card(
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏠 Toplam Portföyüm',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppFormatters.currencyValue(totalValue),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Maliyet: ${AppFormatters.currencyValue(totalCost)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${AppFormatters.signedCurrencyValue(totalProfitLoss)} '
                  '(${AppFormatters.percentValue(totalProfitLossPercent)})',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard({
    required double fundValue,
    required double fundCost,
    required double fundProfitLoss,
    required double fundProfitLossPercent,
    required double stockValue,
    required double stockCost,
    required double stockProfitLoss,
    required double stockProfitLossPercent,
    required double fxValue,
    required double fxCost,
    required double fundPercent,
    required double stockPercent,
  }) {
    return Card(
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dağılım',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _stackedBreakdownRow(
              'Fon',
              fundValue,
              fundCost,
              fundProfitLoss,
              fundProfitLossPercent,
              fundPercent,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _stackedBreakdownRow(
              'Hisse',
              stockValue,
              stockCost,
              stockProfitLoss,
              stockProfitLossPercent,
              stockPercent,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _stackedBreakdownRow(
              'FX',
              fxValue,
              fxCost,
              0.0,
              0.0,
              0.0,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stackedBreakdownRow(
    String label,
    double value,
    double cost,
    double profitLoss,
    double profitLossPercent,
    double percent,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Güncel: ${AppFormatters.currencyValue(value)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maliyet: ${AppFormatters.currencyValue(cost)}',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'K/Z: ${AppFormatters.signedCurrencyValue(profitLoss)} '
                '(${AppFormatters.percentValue(profitLossPercent)})',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: profitLoss >= 0 ? Colors.green : Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pay ${AppFormatters.percentValue(percent)}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
