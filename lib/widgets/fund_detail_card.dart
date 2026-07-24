import 'package:flutter/material.dart';
import '../models/fund.dart';
import 'current_price_card.dart';
import 'fund_header_card.dart';
import 'risk_card.dart';
import 'return_card.dart';

class FundDetailCard extends StatelessWidget {
  final Fund fund;

  const FundDetailCard({
    super.key,
    required this.fund,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FundHeaderCard(
          code: fund.code,
          name: fund.name,
          category: fund.category,
        ),
        const SizedBox(height: 20),
        CurrentPriceCard(price: fund.currentPrice),
        const SizedBox(height: 20),
        ReturnCard(
          title: '1 Yıllık Getiri',
          returnValue: fund.return1Y,
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 12),
        ReturnCard(
          title: 'Gerçek Getiri',
          returnValue: fund.realReturn1Y,
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 20),
        RiskCard(riskScore: fund.riskScore),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text("Sharpe Ratio"),
            trailing: Text(
              fund.sharpe90.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
