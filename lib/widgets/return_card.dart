import 'package:flutter/material.dart';

class ReturnCard extends StatelessWidget {
  final String title;
  final double returnValue;
  final IconData icon;

  const ReturnCard({
    super.key,
    required this.title,
    required this.returnValue,
    this.icon = Icons.trending_up,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = returnValue >= 0;
    final returnColor = isPositive ? Colors.green : Colors.red;
    final returnIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final returnPercentage = returnValue * 100;
    final returnText = '${isPositive ? '+' : ''}${returnPercentage.toStringAsFixed(2)}%';

    return Card(
      margin: EdgeInsets.zero,
      color: returnColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: returnColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                returnIcon,
                color: returnColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    returnText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: returnColor,
                      letterSpacing: 0.5,
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
