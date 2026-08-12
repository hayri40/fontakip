import 'dart:async';

import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';
import '../models/fx_asset.dart';
import '../services/fx_favorites_service.dart';
import '../services/fx_market_service.dart';
import 'fx_detail_screen.dart';

class FxScreen extends StatefulWidget {
  final FxMarketService? marketService;
  final FxFavoritesService? favoritesService;

  const FxScreen({super.key, this.marketService, this.favoritesService});

  @override
  State<FxScreen> createState() => _FxScreenState();
}

class _FxScreenState extends State<FxScreen> {
  late final FxMarketService _marketService;
  late final FxFavoritesService _favoritesService;
  final _searchController = TextEditingController();

  Timer? _debounce;
  bool _searchLoading = false;
  bool _favoritesLoading = true;
  String? _searchError;
  int _selectedIndex = 0;

  List<FxAsset> _results = const <FxAsset>[];
  List<FxAsset> _favorites = const <FxAsset>[];

  @override
  void initState() {
    super.initState();
    _marketService = widget.marketService ?? const FxMarketService();
    _favoritesService = widget.favoritesService ?? FxFavoritesService();
    _loadFavorites();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.loadFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _favoritesLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = const <FxAsset>[];
        _searchError = null;
        _searchLoading = false;
      });
      return;
    }

    setState(() {
      _searchLoading = true;
      _searchError = null;
    });

    try {
      final assets = await _marketService.searchAssets(normalized);
      if (!mounted) return;
      setState(() {
        _results = assets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(FxAsset asset) async {
    await _favoritesService.toggleFavorite(asset);
    await _loadFavorites();
  }

  bool _isFavorite(String id) {
    return _favorites.any((item) => item.id == id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FX'), centerTitle: true),
      body: IndexedStack(
        index: _selectedIndex,
        children: [_buildSearchPage(), _buildFavoritesPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if (index == 1) {
            await _loadFavorites();
          }
          if (!mounted) return;
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Ara'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favoriler'),
        ],
      ),
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Arama',
              hintText: 'USD, Altın, Bitcoin, Brent...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (_searchController.text.trim().isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Enstrüman aramak için yukarıya yazın.'),
                )
              else if (_searchLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _searchError!,
                    style: const TextStyle(color: Colors.orange),
                  ),
                )
              else if (_results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Sonuç bulunamadı.'),
                )
              else
                ..._results.map((asset) => _buildAssetCard(asset)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesPage() {
    if (_favoritesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favorites.isEmpty) {
      return const Center(child: Text('Henüz favori enstrüman eklenmedi.'));
    }

    return ListView(
      children: _favorites.map((asset) => _buildAssetCard(asset)).toList(),
    );
  }

  Widget _buildAssetCard(FxAsset asset) {
    final isFavorite = _isFavorite(asset.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FxDetailScreen(
                initialAsset: asset,
                marketService: _marketService,
                favoritesService: _favoritesService,
              ),
            ),
          );
          await _loadFavorites();
        },
        title: Text(
          asset.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(asset.symbol),
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  AppFormatters.currencyValue(asset.currentPrice),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _toggleFavorite(asset),
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
