enum ExpertRuleCategory {
  riskManagement,
  entryExitStrategy,
  pairVolatility,
  timeframeSessions,
  psychologyDiscipline,
  generalRule
}

extension ExpertRuleCategoryExtension on ExpertRuleCategory {
  String get label {
    switch (this) {
      case ExpertRuleCategory.riskManagement: return 'Risk Yönetimi';
      case ExpertRuleCategory.entryExitStrategy: return 'Giriş ve Çıkış Stratejisi';
      case ExpertRuleCategory.pairVolatility: return 'Parite & Volatilite';
      case ExpertRuleCategory.timeframeSessions: return 'Zaman Dilimi & Seanslar';
      case ExpertRuleCategory.psychologyDiscipline: return 'Psikoloji & Disiplin';
      case ExpertRuleCategory.generalRule: return 'Genel Kural';
    }
  }
}

class ExpertRule {
  final String id;
  final int displayId;
  final String title;
  final String rule;
  final ExpertRuleCategory category;
  final DateTime learnedAt;
  final bool isActive;
  final String? sourceContext;

  ExpertRule({
    required this.id,
    required this.displayId,
    required this.title,
    required this.rule,
    required this.category,
    required this.learnedAt,
    this.isActive = true,
    this.sourceContext,
  });
}

class ExpertChatMessage {
  final String id;
  final String sender; // 'user' | 'expert'
  final String text;
  final DateTime timestamp;
  final ExpertAnalysisSetup? analysisSetup;
  final List<ExpertRule>? learnedRules;

  ExpertChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.analysisSetup,
    this.learnedRules,
  });
}

class ExpertAnalysisSetup {
  final String pair;
  final String timeframe;
  final String action; // 'BUY' | 'SELL' | 'BEKLE'
  final double entryPrice;
  final double stopLoss;
  final double takeProfit1;
  final String? riskRewardRatio;
  final String rationale;

  ExpertAnalysisSetup({
    required this.pair,
    required this.timeframe,
    required this.action,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit1,
    this.riskRewardRatio,
    required this.rationale,
  });
}
