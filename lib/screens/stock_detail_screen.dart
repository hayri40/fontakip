import '../models/stock_favorites_manager.dart';
import 'package:flutter/material.dart';
import '../core/formatters/app_formatters.dart';
import '../models/stock.dart';
import '../services/stock_service.dart';
import 'stock_transaction_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;

  const StockDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<StockDetailScreen> createState() =>
      _StockDetailScreenState();
}

class _StockDetailScreenState
    extends State<StockDetailScreen> {
  final _service = StockService();

  final _favoritesManager = StockFavoritesManager();

  Stock? _stock;
  bool _loading = true;
  String? _error;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    try {
      final stock = await _service.getStockDetail(
        widget.symbol,
      );

      setState(() {
        _stock = stock;
        _loading = false;

        _isFavorite = _favoritesManager.isFavorite(
          stock.symbol,
        );
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    final stock = _stock!;

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.symbol),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    stock.name,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    AppFormatters.currencyValue(stock.currentPrice),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (stock.priceUnavailableMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      stock.priceUnavailableMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _favoritesManager.toggleFavorite(
                              stock.symbol,
                            );

                            setState(() {
                              _isFavorite =
                                  _favoritesManager.isFavorite(
                                    stock.symbol,
                                  );
                            });
                          },
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          label: Text(
                            _isFavorite
                                ? 'Favorilerden Çıkar'
                                : 'Favorilere Ekle',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockTransactionScreen(
                                  symbol: stock.symbol,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_card),
                          label: const Text(
                            'İşlem Ekle',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          _infoTile(
            'Sektör',
            stock.sector,
          ),

          _infoTile(
            'PE',
            AppFormatters.decimalValue(stock.peRatio),
          ),

          _infoTile(
            'EPS',
            AppFormatters.decimalValue(stock.eps),
          ),

          _infoTile(
            'Piyasa Değeri',
            AppFormatters.decimalValue(stock.marketCap),
          ),

          _infoTile(
            'Günlük Aralık',
            AppFormatters.priceRange(stock.dayLow, stock.dayHigh),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
      String title,
      String value,
      ) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}