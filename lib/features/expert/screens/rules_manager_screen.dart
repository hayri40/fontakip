import 'package:flutter/material.dart';
import '../../../models/expert_models.dart';
import '../../../services/expert_firestore_service.dart';

class RulesManagerScreen extends StatefulWidget {
  const RulesManagerScreen({super.key});

  @override
  State<RulesManagerScreen> createState() => _RulesManagerScreenState();
}

class _RulesManagerScreenState extends State<RulesManagerScreen> {
  final ExpertFirestoreService _firestoreService = ExpertFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161922),
        elevation: 0,
        title: const Text('Uzman Hafızası & Kurallar', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ExpertRule>>(
        stream: _firestoreService.streamRules(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rules = snapshot.data!;
          if (rules.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology, size: 48, color: Colors.white10),
                  SizedBox(height: 16),
                  Text('Henüz öğrenilmiş kural yok.', style: TextStyle(color: Colors.white24)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                color: const Color(0xFF1A1D24),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: rule.isActive ? Colors.cyan.withOpacity(0.2) : Colors.white10,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kural #${rule.displayId}',
                              style: const TextStyle(color: Colors.cyan, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                onPressed: () => _deleteRule(rule),
                              ),
                              Switch(
                                value: rule.isActive,
                                onChanged: (val) {
                                  _firestoreService.toggleRuleStatus(rule.id, val);
                                },
                                activeColor: Colors.cyan,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rule.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rule.rule,
                        style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.label_outline, size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            rule.category.label,
                            style: const TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            'Öğrenildi: ${rule.learnedAt.day}.${rule.learnedAt.month}.${rule.learnedAt.year}',
                            style: const TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteRule(ExpertRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuralı Sil'),
        content: Text('${rule.title} kuralını silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteRule(rule.id);
    }
  }
}
