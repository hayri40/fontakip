import 'package:flutter/material.dart';

class FundHeaderCard extends StatelessWidget {
  final String code;
  final String name;
  final String category;

  const FundHeaderCard({
    super.key,
    required this.code,
    required this.name,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1D24),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            // Fon Kodu Rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Fon Bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fon Adı
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Kategori
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
