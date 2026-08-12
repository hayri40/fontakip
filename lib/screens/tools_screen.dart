import 'package:flutter/material.dart';

import 'compound_return_calculator_screen.dart';
import 'global_market_hours_screen.dart';
import 'investment_allocation_planner_screen.dart';
import 'notes_screen.dart';
import 'performance_tracking_screen.dart';
import 'portfolio_balancer_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Araçlar'), centerTitle: true),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
        children: [
          _toolCard(
            context,
            icon: Icons.public,
            title: 'Forex Seans Rehberi',
            subtitle:
                'Forex açık mı, aktif seanslar ve volatiliteyi tek bakışta gör.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GlobalMarketHoursScreen(),
                ),
              );
            },
          ),
          _toolCard(
            context,
            icon: Icons.auto_graph,
            title: 'Yatırım Dağıtım Planlayıcı',
            subtitle:
                'Aylık yatırım bütçesini Fon / Hisse / FX arasında dağıt.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvestmentAllocationPlannerScreen(),
                ),
              );
            },
          ),
          _toolCard(
            context,
            icon: Icons.pie_chart_outline,
            title: 'Portföy Dengeleyici',
            subtitle:
                'Hedef dağılıma ulaşmak için gerekli yatırım tutarlarını hesapla.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PortfolioBalancerScreen(),
                ),
              );
            },
          ),
          _toolCard(
            context,
            icon: Icons.show_chart,
            title: 'Bileşik Getiri Hesaplayıcı',
            subtitle:
                'Sermaye, aylık yatırım ve getiriye göre gelecekteki portföy büyüklüğünü hesapla.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompoundReturnCalculatorScreen(),
                ),
              );
            },
          ),
          _toolCard(
            context,
            icon: Icons.trending_up,
            title: 'Performans Takibi',
            subtitle:
                'Hedef büyüme ile gerçekleşen büyümeyi kayıt bazında karşılaştır.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerformanceTrackingScreen(),
                ),
              );
            },
          ),
          _toolCard(
            context,
            icon: Icons.note_alt_outlined,
            title: 'Notlarım',
            subtitle: 'Yatırım notlarını ve planlarını kaydet.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.cyan, size: 44),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[300], fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
