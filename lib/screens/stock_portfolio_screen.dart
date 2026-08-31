import 'package:flutter/material.dart';

import 'stock_detail_screen.dart';
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
  bool _loading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    
    // Initial sync from cache if available
    if (_service.cachedHoldings != null) {
      _holdings = _service.cachedHoldings!;
      _lastUpdated = _service.lastUpdateTime;
      _loading = false;
    } else {
      _loading = true;
      _loadPortfolio(forceRefresh: false);
    }
  }

  Future<void> _loadPortfolio({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final holdings = await _service.getHoldings(forceRefresh: forceRefresh);

      if (!mounted) return;
      setState(() {
        _holdings = holdings;
        _loading = false;
        _lastUpdated = _service.lastUpdateTime;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Portföy yüklenemedi: $e';
        });
      }
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
                onPressed: () => _loadPortfolio(forceRefresh: true),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_holdings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPortfolio(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Henüz hisse portföyü oluşmadı')),
          ],
        ),
      );
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
      onRefresh: () => _loadPortfolio(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
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
                        onPressed: () => _loadPortfolio(forceRefresh: true),
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
            final profitColor = holding.profitLoss >= 0 ? Colors.green : Colors.red;
            final payPercent = totalCurrent == 0
                ? 0.0
                : (holding.currentValue / totalCurrent) * 100;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockDetailScreen(
                        symbol: holding.symbol,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              holding.symbol,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pay',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  AppFormatters.percentValue(payPercent),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mal_Fiyatı: ${AppFormatters.currencyValue(holding.averageCost)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Adet: ${AppFormatters.quantityLabel(holding.totalQuantity)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toplam: ${AppFormatters.currencyValue(holding.costValue)}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gün_Fiyatı: ${AppFormatters.currencyValue(holding.currentPrice)}',
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'K/Z: ${AppFormatters.signedCurrencyValue(holding.profitLoss)} '
                                '(${AppFormatters.percentValue(holding.profitLossPercent)})',
                                style: TextStyle(
                                  color: profitColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toplam: ${AppFormatters.currencyValue(holding.currentValue)}',
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
