import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expert_models.dart';

class ExpertFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Rules Collection Reference
  CollectionReference<Map<String, dynamic>> get _rulesRef {
    if (_userId == null) throw Exception('Kullanıcı oturumu açılmamış.');
    return _db.collection('users').doc(_userId).collection('expert_rules');
  }

  // Get all rules as a stream
  Stream<List<ExpertRule>> streamRules() {
    return _rulesRef.orderBy('learnedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ExpertRule(
          id: doc.id,
          displayId: data['displayId'] ?? 0,
          title: data['title'] ?? '',
          rule: data['rule'] ?? '',
          category: _parseCategory(data['category']),
          learnedAt: (data['learnedAt'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          sourceContext: data['sourceContext'],
        );
      }).toList();
    });
  }

  // Add a new rule
  Future<void> addRule(ExpertRule rule) async {
    await _rulesRef.add({
      'displayId': rule.displayId,
      'title': rule.title,
      'rule': rule.rule,
      'category': rule.category.name,
      'learnedAt': Timestamp.fromDate(rule.learnedAt),
      'isActive': rule.isActive,
      'sourceContext': rule.sourceContext,
    });
  }

  // Update rule status (Active/Passive)
  Future<void> toggleRuleStatus(String ruleId, bool isActive) async {
    await _rulesRef.doc(ruleId).update({'isActive': isActive});
  }

  // Delete a rule
  Future<void> deleteRule(String ruleId) async {
    await _rulesRef.doc(ruleId).delete();
  }

  ExpertRuleCategory _parseCategory(String? categoryName) {
    return ExpertRuleCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => ExpertRuleCategory.generalRule,
    );
  }

  // --- WATCHLIST & CHART STATE ---

  // Watchlist: Get as stream
  Stream<List<String>> streamWatchlist() {
    return _db.collection('users').doc(_userId).collection('watchlist')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }

  // Watchlist: Toggle favorite
  Future<void> toggleWatchlist(String symbol, bool isFav) async {
    final ref = _db.collection('users').doc(_userId).collection('watchlist').doc(symbol);
    if (isFav) {
      await ref.set({
        'symbol': symbol,
        'createdAt': FieldValue.serverTimestamp(),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  // Chart State: Save last session
  Future<void> saveChartState(String symbol, String timeframe) async {
    await _db.collection('users').doc(_userId).collection('chart_state').doc('current').set({
      'currentSymbol': symbol,
      'lastTimeframe': timeframe,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Chart State: Get last session
  Future<Map<String, dynamic>?> getChartState() async {
    final doc = await _db.collection('users').doc(_userId).collection('chart_state').doc('current').get();
    return doc.data();
  }

  // Drawings: Save (JSON format)
  Future<void> saveDrawings(String symbol, String drawingsData) async {
    await _db.collection('users').doc(_userId).collection('chart_drawings').doc(symbol).set({
      'symbol': symbol,
      'drawings': drawingsData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Drawings: Load
  Future<String?> loadDrawings(String symbol) async {
    final doc = await _db.collection('users').doc(_userId).collection('chart_drawings').doc(symbol).get();
    return doc.data()?['drawings'] as String?;
  }
}
