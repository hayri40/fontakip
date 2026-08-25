import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expert_models.dart';
import 'data_source_settings_service.dart';

class ExpertService {
  final DataSourceSettingsService _settingsService = DataSourceSettingsService.instance;

  Future<ExpertChatMessage> sendMessage({
    required String message,
    required List<ExpertRule> activeRules,
    required List<Map<String, String>> history,
    String symbol = 'GBPCAD',
    String timeframe = '1H',
  }) async {
    final apiKey = await _settingsService.getGeminiApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Gemini API anahtarı bulunamadı. Lütfen Ayarlar > Veri Kaynakları bölümünden ekleyin.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // Or gemini-2.0-flash if available
      apiKey: apiKey,
    );

    final rulesContext = activeRules.isNotEmpty
        ? "MEVCUT ÖĞRENİLMİŞ UZMAN KURALLARI (${activeRules.length} kural aktif):\n" +
            activeRules.asMap().entries.map((e) => "${e.key + 1}. [${e.value.category.name}] ${e.value.title}: ${e.value.rule}").join('\n')
        : 'Henüz özel kural tanımlanmamış, standart profesyonel kurallar geçerlidir.';

    final systemInstruction = """
Sen kullanıcı için çalışan tek, kıdemli ve disiplinli bir **FX Baş Stratejisti & Teknik Analiz Danışmanısın**.
Kullanıcı seninle Türkçe konuşur. Sen de profesyonel, samimi, disiplinli ve piyasa gerçeklerine uygun bir dille yanıt verirsin.

TEMEL PRENSİPLERİN VE GÖREVLERİN:
1. **Piyasa Analizi ve İşlem Kurulumları**:
   - Kullanıcı senden analiz, destek-direnç, trend kanalı, işleme giriş, TP (Kâr Al), SL (Zarar Durdur) seviyeleri istediğinde veya genel teknik durumu sorduğunda (Örn: $symbol $timeframe):
   - Fiyat seviyelerini gerçekçi, orantılı ve net belirle.
   - Stop Loss (SL) ve Take Profit (TP1, TP2) seviyelerini kesinlikle Risk/Ödül oranı minimum 1:2 olacak şekilde hesapla.

2. **Kural Öğrenme ve Hafızaya Kaydetme (Çok Önemli)**:
   - Kullanıcıyla sohbet ederken, kullanıcının belirttiği veya birlikte kararlaştırdığınız strateji, risk yönetimi, işlem açma saatleri, seans tercihleri, parite kuralları, lot disiplini gibi İLKELERİ/KURALLARI tespit et.
   - Yeni bir kural veya ilke çıktığında bunu 'newRules' listesinde yapılandırılmış olarak döndür.

3. **Mevcut Kurallara Bağlılık**:
   $rulesContext
   - Analiz ve öneri sunarken kullanıcının bu mevcut kurallarına titizlikle sadık kal!

ÇIKTI FORMATI:
SADECE GEÇERLİ JSON FORMATINDA CEVAP VER. Şema:
{
  "message": "Kullanıcıya Türkçe açıklayıcı, profesyonel uzman analizi ve değerlendirmesi (Markdown formatında, maddeler halinde)",
  "analysisSetup": {
    "pair": "$symbol",
    "timeframe": "$timeframe",
    "action": "BUY" | "SELL" | "BEKLE",
    "entryPrice": 1.74520,
    "stopLoss": 1.74100,
    "takeProfit1": 1.75360,
    "riskRewardRatio": "1:2.0",
    "rationale": "Teknik kurulum gerekçesi ve risk yönetimi uyarısı"
  },
  "newRules": [
    {
      "title": "Kural Başlığı",
      "rule": "Öğrenilen kuralın net ve uygulanabilir metni",
      "category": "riskManagement" | "entryExitStrategy" | "pairVolatility" | "timeframeSessions" | "psychologyDiscipline" | "generalRule"
    }
  ]
}
""";

    final chat = model.startChat(
      history: history.map((m) => Content.text(m['text'] ?? '')).toList(), // Simplified history
    );

    // In current SDK, system instructions can be part of the first message or specialized.
    // We'll append it to the prompt for simplicity if systemInstruction parameter is not directly supported in the model constructor of the specific version.
    final prompt = "$systemInstruction\n\nKullanıcı Mesajı: $message";
    
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null) throw Exception('AI yanıt vermedi.');

    try {
      // Clean potential markdown blocks
      final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanedText);

      return ExpertChatMessage(
        id: DateTime.now().toString(),
        sender: 'expert',
        text: data['message'] ?? '',
        timestamp: DateTime.now(),
        analysisSetup: data['analysisSetup'] != null
            ? ExpertAnalysisSetup(
                pair: data['analysisSetup']['pair'] ?? symbol,
                timeframe: data['analysisSetup']['timeframe'] ?? timeframe,
                action: data['analysisSetup']['action'] ?? 'BEKLE',
                entryPrice: (data['analysisSetup']['entryPrice'] ?? 0).toDouble(),
                stopLoss: (data['analysisSetup']['stopLoss'] ?? 0).toDouble(),
                takeProfit1: (data['analysisSetup']['takeProfit1'] ?? 0).toDouble(),
                riskRewardRatio: data['analysisSetup']['riskRewardRatio'],
                rationale: data['analysisSetup']['rationale'] ?? '',
              )
            : null,
        learnedRules: data['newRules'] != null
            ? (data['newRules'] as List).map((r) => ExpertRule(
                id: '', // Will be set by Firestore
                displayId: 0,
                title: r['title'] ?? '',
                rule: r['rule'] ?? '',
                category: _parseCategory(r['category']),
                learnedAt: DateTime.now(),
              )).toList()
            : null,
      );
    } catch (e) {
      // Fallback if JSON parsing fails
      return ExpertChatMessage(
        id: DateTime.now().toString(),
        sender: 'expert',
        text: text,
        timestamp: DateTime.now(),
      );
    }
  }

  ExpertRuleCategory _parseCategory(String? categoryName) {
    return ExpertRuleCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => ExpertRuleCategory.generalRule,
    );
  }
}
