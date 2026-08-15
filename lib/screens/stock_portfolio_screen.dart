import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';
import '../models/stock_holding.dart';
import '../services/stock_portfolio_service.dart';

class StockPortfolioScreen extends StatefulWidget {
  const StockPortfolioScreen({super.key});

  @override
  State<StockPortfolioScreen> createState() => _StockPortfolioScreenState();
}

class _StockPortfolioScreenState extends State<StockPortfolioScreen> {
  final _service = StockPortfolioService();

  List<StockHolding> _holdings = [];
  bool _loading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final holdings = await _service.getHoldings();

      setState(() {
        _holdings = holdings;
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Portföy yüklenemedi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPortfolio,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_holdings.isEmpty) {
      return const Center(child: Text('Henüz hisse portföyü oluşmadı'));
    }

    final totalCost = _holdings.fold(0.0, (sum, item) => sum + item.costValue);
    final totalCurrent = _holdings.fold(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    final totalProfitLoss = _holdings.fold(
      0.0,
      (sum, item) => sum + item.profitLoss,
    );
    final totalProfitLossPercent = totalCost == 0
        ? 0.0
        : (totalProfitLoss / totalCost) * 100;

    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toplam Hisse Portföyü',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Yenile',
                        onPressed: _loadPortfolio,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.currencyValue(totalCurrent),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Maliyet: ${AppFormatters.currencyValue(totalCost)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'K/Z: ${AppFormatters.signedCurrencyValue(totalProfitLoss)} '
                    '(${AppFormatters.percentValue(totalProfitLossPercent)})',
                    style: TextStyle(
                      color: totalProfitLoss >= 0 ? Colors.green : Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastUpdated == null
                        ? ''
                        : 'Son güncelleme: '
                              '${_lastUpdated!.hour.toString().padLeft(2, '0')}:'
                              '${_lastUpdated!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          ..._holdings.map((holding) {
            final isProfit = holding.profitLoss >= 0;
            final profitColor = isProfit ? Colors.green : Colors.red;
            final dailyColor = holding.dailyChangeValue >= 0
                ? Colors.green
                : Colors.red;
            final dailyArrow = holding.dailyChangeValue >= 0 ? '▲' : '▼';
            final payPercent = totalCurrent == 0
                ? 0.0
                : (holding.currentValue / totalCurrent) * 100;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${holding.symbol} (${AppFormatters.currencyValue(holding.currentPrice)})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ort. Maliyet: ${AppFormatters.currencyValue(holding.averageCost)}',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Güncel: ${AppFormatters.currencyValue(holding.currentValue)}',
                                style: const TextStyle(color: Colors.cyan),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Maliyet: ${AppFormatters.currencyValue(holding.costValue)}',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: dailyColor.withOpacity(0.09),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Günlük',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                  Text(
                                      dailyArrow,
                                      style: TextStyle(
                                        color: dailyColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppFormatters.signedPercentValue(
                                        holding.dailyChangePercent,
                                      ),
                                      style: TextStyle(
                                        color: dailyColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.signedCurrencyValue(
                                    holding.dailyChangeValue,
                                  ),
                                  style: TextStyle(
                                    color: dailyColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                                ),
                              ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.quantityLabel(holding.totalQuantity),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pay ${AppFormatters.percentValue(payPercent)}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Toplam K/Z: ${AppFormatters.signedCurrencyValue(holding.profitLoss)} '
                                  '(${AppFormatters.percentValue(holding.profitLossPercent)})',
                                  style: TextStyle(
                                    color: profitColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
