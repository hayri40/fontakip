import 'package:flutter/material.dart';
import '../widgets/trading_view_chart.dart';

class FullscreenChartScreen extends StatelessWidget {
  final String symbol;

  const FullscreenChartScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131722),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161922),
        elevation: 0,
        title: Text(symbol, style: const TextStyle(fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.fullscreen_exit),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: TradingViewChart(
          symbol: symbol,
          showControls: true,
        ),
      ),
    );
  }
}
