import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';
import '../models/fx_asset.dart';
import '../services/fx_favorites_service.dart';
import '../services/fx_market_service.dart';

class FxDetailScreen extends StatefulWidget {
  final FxAsset initialAsset;
  final FxMarketService? marketService;
  final FxFavoritesService? favoritesService;

  const FxDetailScreen({
    super.key,
    required this.initialAsset,
    this.marketService,
    this.favoritesService,
  });

  @override
  State<FxDetailScreen> createState() => _FxDetailScreenState();
}

class _FxDetailScreenState extends State<FxDetailScreen> {
  late final FxMarketService _marketService;
  late final FxFavoritesService _favoritesService;
  late FxAsset _asset;
  bool _isFavorite = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _marketService = widget.marketService ?? const FxMarketService();
    _favoritesService = widget.favoritesService ?? FxFavoritesService();
    _asset = widget.initialAsset;
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadFavoriteState();
    await _loadLatestDetail();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadFavoriteState() async {
    final favorites = await _favoritesService.loadFavorites();
    if (!mounted) return;
    setState(() {
      _isFavorite = favorites.any((item) => item.id == _asset.id);
    });
  }

  Future<void> _loadLatestDetail() async {
    try {
      final detail = await _marketService.getDetailBySymbol(
        symbol: _asset.symbol,
        name: _asset.name,
        type: _asset.type,
      );
      _asset = _asset.copyWith(
        currentPrice: detail.currentPrice,
        changePercent: detail.changePercent,
        dayHigh: detail.dayHigh,
        dayLow: detail.dayLow,
      );
      if (_isFavorite) {
        await _favoritesService.upsertFavorite(_asset);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavorite(_asset);
    final updated = await _favoritesService.isFavorite(_asset.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final asset = _asset;
    final changeColor = (asset.changePercent ?? 0) >= 0
        ? Colors.green
        : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(asset.symbol)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    asset.symbol,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppFormatters.currencyValue(asset.currentPrice),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.signedPercentValue(asset.changePercent),
                    style: TextStyle(
                      fontSize: 16,
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Favori Durumu:'),
                      const SizedBox(width: 8),
                      Text(
                        _isFavorite ? 'Favorilerde' : 'Favorilerde değil',
                        style: TextStyle(
                          color: _isFavorite ? Colors.amber : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.orange)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _toggleFavorite,
                    icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
                    label: Text(
                      _isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Günlük Yüksek'),
              trailing: Text(
                AppFormatters.currencyValue(asset.dayHigh),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Günlük Düşük'),
              trailing: Text(
                AppFormatters.currencyValue(asset.dayLow),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
