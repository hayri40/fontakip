import 'package:flutter/material.dart';
import '../../../models/expert_models.dart';
import 'package:intl/intl.dart';

class ExpertChatBubble extends StatelessWidget {
  final ExpertChatMessage message;
  final Function(ExpertRule)? onSaveRule;

  const ExpertChatBubble({super.key, required this.message, this.onSaveRule});

  @override
  Widget build(BuildContext context) {
    // Determine if the message is from the expert
    final isExpert = message.sender == 'expert';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isExpert ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isExpert) ...[
                const Icon(Icons.auto_awesome, size: 12, color: Colors.cyan),
                const SizedBox(width: 4),
                const Text(
                  'FX Uzmanı',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ] else
                const Text(
                  'Siz',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExpert ? const Color(0xFF1E222D) : Colors.cyan.shade700,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isExpert ? 0 : 16),
                bottomRight: Radius.circular(isExpert ? 16 : 0),
              ),
              border: isExpert ? Border.all(color: Colors.white10) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
                ),
                if (message.analysisSetup != null) _buildAnalysisCard(message.analysisSetup!),
                if (message.learnedRules != null && message.learnedRules!.isNotEmpty)
                  _buildLearnedRules(context, message.learnedRules!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnedRules(BuildContext context, List<ExpertRule> rules) {
    return Column(
      children: rules.map((rule) {
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yeni Kural Önerisi: ${rule.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4CAF50)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(rule.rule, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSaveRule != null ? () => onSaveRule!(rule) : null,
                  icon: const Icon(Icons.save, size: 14),
                  label: const Text('Hafızaya Ekle', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisCard(ExpertAnalysisSetup setup) {
    final isBuy = setup.action == 'BUY';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBuy ? const Color(0xFF4CAF50) : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      setup.action,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${setup.pair} (${setup.timeframe})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              if (setup.riskRewardRatio != null)
                Text(
                  'R:R ${setup.riskRewardRatio}',
                  style: const TextStyle(fontSize: 10, color: Colors.cyan),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _priceBox('GİRİŞ', setup.entryPrice.toString(), Colors.blue),
              const SizedBox(width: 8),
              _priceBox('SL', setup.stopLoss.toString(), Colors.red),
              const SizedBox(width: 8),
              _priceBox('TP', setup.takeProfit1.toString(), const Color(0xFF4CAF50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceBox(String label, String price, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
