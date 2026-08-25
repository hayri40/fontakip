import 'package:flutter/material.dart';
import '../features/expert/screens/fx_strategist_hub_screen.dart';
import 'fx_screen.dart';
import 'general_portfolio_screen.dart';
import 'stock_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finans Merkezi'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GeneralPortfolioScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.home,
                      color: Colors.cyan,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏠 Genel Portföyüm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          _menuItem(
            context,
            icon: Icons.account_balance,
            title: 'FON',
            subtitle: 'Portföy ve Fon Takibi',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PortfolioScreen(),
                ),
              );
            },
          ),

          _menuItem(
            context,
            icon: Icons.show_chart,
            title: 'HİSSE',
            subtitle: 'Borsa İstanbul',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockScreen(),
                ),
              );
            },
          ),

          _menuItem(
            context,
            icon: Icons.currency_exchange,
            title: 'FX',
            subtitle: 'Döviz, emtia ve kripto takibi',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FxStrategistHubScreen(),
                ),
              );
            },
          ),

          _menuItem(
            context,
            icon: Icons.calculate,
            title: 'ARAÇLAR',
            subtitle: 'Finansal araçlar ve planlama',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ToolsScreen(),
                ),
              );
            },
          ),

          _menuItem(
            context,
            icon: Icons.settings,
            title: 'AYARLAR',
            subtitle: 'Veri ve uygulama ayarları',
            color: Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),

          _menuItem(
            context,
            icon: Icons.logout,
            title: 'ÇIKIŞ',
            subtitle: 'Uygulamadan Çık',
            color: Colors.red,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Icon(
          icon,
          color: color,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

}