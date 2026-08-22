import 'package:flutter/material.dart';
import 'stock_detail_screen.dart';
import 'stock_portfolio_screen.dart';
import '../models/stock.dart';
import '../services/stock_service.dart';
import '../models/stock_favorites_manager.dart';
import 'stock_transactions_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _service = StockService();
  final _searchController = TextEditingController();
  final _favoritesManager = StockFavoritesManager();

  List<String> _favoriteStocks = [];
  int _selectedTabIndex = 0;

  List<Stock> _results = [];
  bool _searchLoading = false;
  String? _searchError;

  Future<void> _searchStocks() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _searchLoading = true;
      _searchError = null;
    });

    try {
      final results =
      await _service.searchStocks(query);

      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
      });
    } finally {
      setState(() {
        _searchLoading = false;
      });
    }
  }
  Future<void> _loadFavorites() async {
    await _favoritesManager.loadFavorites();

    setState(() {
      _favoriteStocks =
          _favoritesManager.getFavorites();
    });
  }

  @override
  void initState() {
    super.initState();

    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          if (index == 3) {
            await _loadFavorites();
          }

          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portföy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Ara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'İşlemler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (_selectedTabIndex) {
      case 0:
        return 'Hisse Portföyüm';
      case 1:
        return 'Hisse Ara';
      case 2:
        return 'Hisse İşlemleri';
      case 3:
        return 'Hisse Favorileri';
      default:
        return 'Hisse';
    }
  }

  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0:
        return const StockPortfolioScreen();

      case 1:
        return _buildSearchTab();

      case 2:
        return const StockTransactionsScreen();

      case 3:
        return ListView.builder(
          itemCount: _favoriteStocks.length,
          itemBuilder: (context, index) {
            final code = _favoriteStocks[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                title: Text(code),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockDetailScreen(
                        symbol: code,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textCapitalization:
                  TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Hisse Kodu',
                    hintText: 'THYAO',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _searchStocks(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchStocks,
                child: const Text('Ara'),
              ),
            ],
          ),
        ),

        if (_searchLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_searchError != null)
          Expanded(
            child: Center(
              child: Text(
                _searchError!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final stock = _results[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(
                            symbol: stock.symbol,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      stock.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(stock.name),
                    trailing: Text(stock.sector),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _placeholder(
      IconData icon,
      String text,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}