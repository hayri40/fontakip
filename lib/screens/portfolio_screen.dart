import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fund.dart';
import '../models/history_point.dart';
import '../models/favorites_manager.dart';
import '../services/fonoloji_service.dart';
import '../widgets/search_fund_box.dart';
import '../widgets/favorites_tab.dart';
import '../widgets/enhanced_fund_history_chart.dart';
import '../features/transactions/screens/transactions_screen.dart';
import 'portfolio_dashboard_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _service = FonolojiService();
  final _favoritesManager = FavoritesManager();
  final _searchController = TextEditingController();
  
  Fund? _currentFund;
  String _errorMessage = '';
  bool _isLoading = false;
  int _selectedTabIndex = 0;
  
  List<HistoryPoint> _history = [];
  bool _historyLoading = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();

    _initialize();
  }
  Future<void> _initialize() async {
    await _favoritesManager.loadFavorites();

    final prefs = await SharedPreferences.getInstance();

    final lastFund =
        prefs.getString('last_fund_code') ?? 'KLU';

    await _loadFund(lastFund);
  }

  Future<void> _loadFund(String code) async {
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a fund code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _historyLoading = true;
      _historyError = null;
    });

    try {
      final fund = await _service.getFund(code.toUpperCase());
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'last_fund_code',
        code.toUpperCase(),
      );
      setState(() {
        _currentFund = fund;
        _searchController.text = code.toUpperCase();
      });
      
      _loadHistory(code.toUpperCase());
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading fund: ${e.toString()}';
        _currentFund = null;
        _historyLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory(String code) async {
    try {
      final history = await _service.getHistory(code);
      print('✅ History loaded: ${history.length} points');
      if (history.isNotEmpty) {
        print('   First: ${history.first.date} = ₺${history.first.price}');
        print('   Last: ${history.last.date} = ₺${history.last.price}');
      }
      setState(() {
        _history = history;
        _historyError = null;
      });
    } catch (e) {
      print('❌ History error: $e');
      setState(() {
        _historyError = 'Failed to load chart: ${e.toString()}';
        _history = [];
      });
    } finally {
      setState(() {
        _historyLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentFund == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load a fund first')),
      );
      return;
    }

    await _favoritesManager.toggleFavorite(_currentFund!.code);

    setState(() {});

    final isFav = _favoritesManager.isFavorite(_currentFund!.code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav ? 'Added to favorites' : 'Removed from favorites',
        ),
      ),
    );
  }

  void _onFavoriteSelected(String code) {
    _searchController.text = code;
    setState(() {
      _selectedTabIndex = 1;
    });
    _loadFund(code);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        onTap: (index) {
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
        return 'Portföyüm';
      case 1:
        return 'FonTakip';
      case 2:
        return 'İşlemler';
      case 3:
        return 'Favoriler';
      default:
        return 'FonTakip';
    }
  }

  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0:
        return const PortfolioDashboardScreen();

      case 1:
        return _buildSearchTab();

      case 2:
        return const TransactionsScreen();

      case 3:
        return _buildFavoritesTab();

      default:
        return _buildSearchTab();
    }
  }

  Widget _buildSearchTab() {
    if (_isLoading) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SearchFundBox(
              controller: _searchController,
              onSearch: () => _loadFund(_searchController.text),
              onAddFavorite: _toggleFavorite,
              isFavorite: _currentFund != null && 
                  _favoritesManager.isFavorite(_currentFund!.code),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SearchFundBox(
              controller: _searchController,
              onSearch: () => _loadFund(_searchController.text),
              onAddFavorite: _toggleFavorite,
              isFavorite: _currentFund != null && 
                  _favoritesManager.isFavorite(_currentFund!.code),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_currentFund == null) {
      return SearchFundBox(
        controller: _searchController,
        onSearch: () => _loadFund(_searchController.text),
        onAddFavorite: _toggleFavorite,
        isFavorite: false,
      );
    }

    // TradingView-style layout
    return SingleChildScrollView(
      child: Column(
        children: [
          SearchFundBox(
            controller: _searchController,
            onSearch: () => _loadFund(_searchController.text),
            onAddFavorite: _toggleFavorite,
            isFavorite: _favoritesManager.isFavorite(_currentFund!.code),
          ),
          // Fund info header (above chart)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fund name and code
                Text(
                  _currentFund!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                // Current price and return
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₺${_currentFund!.currentPrice.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentFund!.return1Y >= 0
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_currentFund!.return1Y >= 0 ? '+' : ''}${_currentFund!.return1Y.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentFund!.return1Y >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main chart (star of the show)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EnhancedFundHistoryChart(
              history: _history,
              isLoading: _historyLoading,
              errorMessage: _historyError,
            ),
          ),
          // Metrics below chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Risk score
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMetricRow(
                    'Risk Score',
                    _currentFund!.riskScore.toString(),
                    _getRiskColor(_currentFund!.riskScore),
                    _getRiskIcon(_currentFund!.riskScore),
                  ),
                ),
                // Real return
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMetricRow(
                    'Real Return',
                    '${_currentFund!.realReturn1Y >= 0 ? '+' : ''}${_currentFund!.realReturn1Y.toStringAsFixed(2)}%',
                    _currentFund!.realReturn1Y >= 0 ? Colors.green : Colors.red,
                    _currentFund!.realReturn1Y >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                  ),
                ),
                // Sharpe ratio
                _buildMetricRow(
                  'Sharpe Ratio',
                  _currentFund!.sharpe90.toStringAsFixed(2),
                  Colors.cyan,
                  Icons.auto_graph,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore <= 2) return Colors.green;
    if (riskScore <= 4) return Colors.amber;
    return Colors.red;
  }

  IconData _getRiskIcon(int riskScore) {
    if (riskScore <= 2) return Icons.shield;
    if (riskScore <= 4) return Icons.warning;
    return Icons.error;
  }

  Widget _buildFavoritesTab() {
    return FavoritesTab(
      favorites: _favoritesManager.getFavorites(),
      onFavoriteSelected: _onFavoriteSelected,
    );
  }
}
