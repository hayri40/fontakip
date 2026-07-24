import 'package:flutter/material.dart';

class RiskCard extends StatelessWidget {
  final int riskScore;

  const RiskCard({
    super.key,
    required this.riskScore,
  });

  Map<String, dynamic> _getRiskColor(int score) {
    try {
      final riskValue = score;
      
      if (riskValue >= 1 && riskValue <= 2) {
        return {
          'color': Colors.green,
          'bgColor': Colors.green.withOpacity(0.1),
          'icon': Icons.shield_outlined,
          'label': 'Düşük Risk'
        };
      } else if (riskValue >= 3 && riskValue <= 4) {
        return {
          'color': Colors.amber,
          'bgColor': Colors.amber.withOpacity(0.1),
          'icon': Icons.warning_outlined,
          'label': 'Orta Risk'
        };
      } else if (riskValue >= 5 && riskValue <= 7) {
        return {
          'color': Colors.red,
          'bgColor': Colors.red.withOpacity(0.1),
          'icon': Icons.error_outline,
          'label': 'Yüksek Risk'
        };
      }
    } catch (_) {}
    
    return {
      'color': Colors.grey,
      'bgColor': Colors.grey.withOpacity(0.1),
      'icon': Icons.help_outline,
      'label': 'Belirsiz'
    };
  }

  @override
  Widget build(BuildContext context) {
    final riskInfo = _getRiskColor(riskScore);
    
    return Card(
      margin: EdgeInsets.zero,
      color: riskInfo['bgColor'],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskInfo['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                riskInfo['icon'],
                color: riskInfo['color'],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Skoru',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        riskScore.toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: riskInfo['color'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          riskInfo['label'],
                          style: TextStyle(
                            fontSize: 13,
                            color: riskInfo['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
