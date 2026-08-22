import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';

class CurrentPriceCard extends StatelessWidget {
  final double price;

  const CurrentPriceCard({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1D24),
      elevation: 4,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 32 : 40,
          horizontal: isMobile ? 20 : 32,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppFormatters.currencyValue(price),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 48 : 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Güncel Fiyat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
