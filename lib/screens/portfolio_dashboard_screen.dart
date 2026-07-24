import 'package:flutter/material.dart';

import '../models/holding.dart';
import '../services/portfolio_service.dart';

class PortfolioDashboardScreen extends StatefulWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  State<PortfolioDashboardScreen> createState() =>
      _PortfolioDashboardScreenState();
}

class _PortfolioDashboardScreenState
    extends State<PortfolioDashboardScreen> {
  final _service = PortfolioService();

  List<Holding> _holdings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final holdings = await _service.getHoldings();

    setState(() {
      _holdings = holdings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_holdings.isEmpty) {
      return const Center(
        child: Text(
          'Henüz portföy oluşmadı',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _holdings.length,
      itemBuilder: (context, index) {
        final holding = _holdings[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              holding.fundCode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Ortalama Maliyet: '
                  '${holding.averageCost.toStringAsFixed(4)} TL',
            ),
            trailing: Text(
              '${holding.quantity.toInt()} Adet',
            ),
          ),
        );
      },
    );
  }
}
