import 'package:flutter/material.dart';

class ExpertActionBar extends StatelessWidget {
  final Function(String) onCommand;

  const ExpertActionBar({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    final commands = [
      '⚡ GBPCAD H1 Analiz Et',
      '🎯 İşlem Kurulumu İste',
      '📊 Bölgeleri Belirle',
      '🛡️ Risk Kuralları',
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: commands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => onCommand(commands[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                commands[index],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }
}
