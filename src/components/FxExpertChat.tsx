import React, { useState, useEffect, useRef } from 'react';
import {
  Brain,
  Send,
  Sparkles,
  ChevronDown,
  ChevronUp,
  Target,
  ShieldCheck,
  TrendingUp,
  TrendingDown,
  CheckCircle2,
  Trash2,
  Maximize2,
  Minimize2,
  Layers,
  ArrowRight,
  Sliders,
  AlertCircle,
  Clock,
  Loader2,
} from 'lucide-react';
import { ExpertChatMessage, ExpertAnalysisSetup, ExpertRule } from '../types';
import { StorageService } from '../services/storage';

interface FxExpertChatProps {
  currentSymbol: string;
  currentTimeframe: string;
  onAnalysisGenerated?: (setup: ExpertAnalysisSetup | null) => void;
  activeAnalysisSetup?: ExpertAnalysisSetup | null;
}

export const FxExpertChat: React.FC<FxExpertChatProps> = ({
  currentSymbol,
  currentTimeframe,
  onAnalysisGenerated,
  activeAnalysisSetup,
}) => {
  const [messages, setMessages] = useState<ExpertChatMessage[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isExpanded, setIsExpanded] = useState(true);
  const [activeRulesCount, setActiveRulesCount] = useState<number>(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load chat history & rules count on mount
  useEffect(() => {
    const history = StorageService.getExpertChatHistory();
    if (history.length === 0) {
      // Initial welcome message from the single expert
      const initialMessage: ExpertChatMessage = {
        id: 'msg-init',
        sender: 'expert',
        text: `Merhaba! Ben sizin FX Baş Stratejistiniz ve Teknik Analiz Danışmanınızım. 

Öğrendiğim tüm risk ve işlem kurallarını hafızamda tutuyorum. Aşağıdaki grafiğe bakarak destek-direnç bölgelerini, trend kanallarını ve minimum 1:2 Risk/Ödül oranına sahip **Giriş, TP ve Stop Loss** seviyelerini belirleyebilirim.

Ayrıca benimle konuşurken belirleyeceğimiz tüm yeni kuralları **Uzman Kuralları** paneline otomatik kaydedeceğim. Ne analiz etmek istersiniz?`,
        timestamp: new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages([initialMessage]);
      StorageService.saveExpertChatHistory([initialMessage]);
    } else {
      setMessages(history);
    }

    const rules = StorageService.getExpertRules();
    setActiveRulesCount(rules.filter((r) => r.isActive).length);
  }, []);

  // Auto scroll to bottom of messages
  useEffect(() => {
    if (isExpanded) {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, isExpanded, isLoading]);

  const handleSendMessage = async (customPrompt?: string) => {
    const textToSend = customPrompt || inputText;
    if (!textToSend.trim() || isLoading) return;

    const userMessage: ExpertChatMessage = {
      id: 'user-' + Date.now(),
      sender: 'user',
      text: textToSend.trim(),
      timestamp: new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }),
    };

    const updatedMessages = [...messages, userMessage];
    setMessages(updatedMessages);
    setInputText('');
    setIsLoading(true);

    try {
      const currentRules = StorageService.getExpertRules().filter((r) => r.isActive);

      const response = await fetch('/api/expert/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: textToSend,
          currentRules,
          history: updatedMessages.slice(-6).map((m) => ({ sender: m.sender, text: m.text })),
          symbol: currentSymbol || 'GBPCAD',
          timeframe: currentTimeframe || '1H',
        }),
      });

      if (!response.ok) {
        throw new Error(`Sunucu yanıt vermedi (${response.status})`);
      }

      const data = await response.json();

      // If new rules were learned by the expert, add them to storage
      if (Array.isArray(data.newRules) && data.newRules.length > 0) {
        data.newRules.forEach((nr: any) => {
          if (nr.title && nr.rule) {
            StorageService.addExpertRule({
              title: nr.title,
              rule: nr.rule,
              category: nr.category || 'Genel Kural',
              isActive: true,
              sourceContext: nr.sourceContext || 'Sohbet sırasında öğrenildi',
            });
          }
        });
        const freshRules = StorageService.getExpertRules();
        setActiveRulesCount(freshRules.filter((r) => r.isActive).length);
      }

      const expertMessage: ExpertChatMessage = {
        id: 'expert-' + Date.now(),
        sender: 'expert',
        text: data.message || 'Analiz tamamlandı.',
        timestamp: new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }),
        analysisSetup: data.analysisSetup || undefined,
        learnedRules: data.newRules || undefined,
      };

      const finalMessages = [...updatedMessages, expertMessage];
      setMessages(finalMessages);
      StorageService.saveExpertChatHistory(finalMessages);

      if (data.analysisSetup && onAnalysisGenerated) {
        onAnalysisGenerated(data.analysisSetup);
      }
    } catch (err: any) {
      console.error('Chat error:', err);
      const errorMessage: ExpertChatMessage = {
        id: 'expert-err-' + Date.now(),
        sender: 'expert',
        text: `⚠️ Bir hata oluştu: ${err.message || 'Yanıt alınamadı'}. Lütfen tekrar deneyin.`,
        timestamp: new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }),
      };
      const finalMessages = [...updatedMessages, errorMessage];
      setMessages(finalMessages);
      StorageService.saveExpertChatHistory(finalMessages);
    } finally {
      setIsLoading(false);
    }
  };

  const handleClearChat = () => {
    if (confirm('Uzman ile olan sohbet geçmişini temizlemek istiyor musunuz? (Öğrenilen kurallar silinmez)')) {
      StorageService.clearExpertChatHistory();
      setMessages([]);
      if (onAnalysisGenerated) onAnalysisGenerated(null);
    }
  };

  const quickPrompts = [
    `⚡ ${currentSymbol || 'GBPCAD'} H1 Analiz Et & Seviyeleri Çiz`,
    `🎯 Giriş, TP ve SL İşlem Kurulumu Belirle`,
    `📊 Destek, Direnç & Likidite Bölgelerini Bul`,
    `🛡️ Aktif Risk Yönetimi Kurallarımızı Özetle`,
  ];

  return (
    <div className="bg-[#141824] border border-cyan-500/20 rounded-2xl overflow-hidden shadow-2xl transition-all duration-200">
      {/* Header Bar */}
      <div className="bg-[#101420] border-b border-slate-800/80 px-4 py-3 flex items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="relative">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-cyan-600 to-blue-500 flex items-center justify-center text-white shadow-md">
              <Brain className="w-4 h-4" />
            </div>
            <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-emerald-400 border-2 border-[#101420] animate-pulse" />
          </div>

          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-xs sm:text-sm font-bold text-white flex items-center gap-1.5">
                <span>FX Baş Stratejisti</span>
                <span className="text-[10px] px-1.5 py-0.2 rounded bg-cyan-500/15 text-cyan-400 border border-cyan-500/30 font-mono font-medium">
                  UZMAN
                </span>
              </h3>
              <span className="text-slate-600 hidden sm:inline">•</span>
              <span className="text-[11px] text-slate-400 hidden sm:inline font-mono">
                {currentSymbol || 'GBPCAD'} • {currentTimeframe || '1H'}
              </span>
            </div>
            <div className="text-[11px] text-slate-400 flex items-center gap-2">
              <span>Hafıza & Kurallar:</span>
              <span className="text-emerald-400 font-bold flex items-center gap-1">
                <ShieldCheck className="w-3 h-3 text-emerald-400" />
                {activeRulesCount} Aktif Kural
              </span>
            </div>
          </div>
        </div>

        {/* Action buttons */}
        <div className="flex items-center gap-1.5">
          {activeAnalysisSetup && (
            <span className="hidden md:flex items-center gap-1 text-[11px] font-bold px-2 py-1 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/25 animate-pulse">
              <Target className="w-3 h-3" />
              Grafik Çizimleri Aktif
            </span>
          )}

          <button
            onClick={handleClearChat}
            title="Sohbeti Temizle"
            className="p-1.5 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-400 hover:text-white transition"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>

          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-1.5 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-white transition flex items-center gap-1 text-xs font-semibold"
          >
            {isExpanded ? (
              <>
                <ChevronUp className="w-4 h-4" />
                <span className="hidden sm:inline text-[11px]">Küçült</span>
              </>
            ) : (
              <>
                <ChevronDown className="w-4 h-4" />
                <span className="hidden sm:inline text-[11px]">Genişlet</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Expandable Chat Body */}
      {isExpanded && (
        <div className="flex flex-col">
          {/* Messages list */}
          <div className="max-h-[300px] sm:max-h-[360px] overflow-y-auto p-4 space-y-3.5 bg-gradient-to-b from-[#121622] to-[#0F121C] scrollbar-thin scrollbar-thumb-slate-800">
            {messages.map((msg) => {
              const isExpert = msg.sender === 'expert';
              return (
                <div
                  key={msg.id}
                  className={`flex flex-col ${isExpert ? 'items-start' : 'items-end'} space-y-1.5 max-w-[95%] sm:max-w-[85%] ${
                    isExpert ? 'mr-auto' : 'ml-auto'
                  }`}
                >
                  <div className="flex items-center gap-1.5 text-[10px] text-slate-400 px-1">
                    {isExpert ? (
                      <>
                        <Sparkles className="w-3 h-3 text-cyan-400" />
                        <span className="font-semibold text-cyan-400">FX Uzmanı</span>
                      </>
                    ) : (
                      <span className="font-semibold text-slate-300">Siz</span>
                    )}
                    <span>•</span>
                    <span>{msg.timestamp}</span>
                  </div>

                  <div
                    className={`p-3 sm:p-3.5 rounded-2xl text-xs sm:text-sm leading-relaxed ${
                      isExpert
                        ? 'bg-[#181D2D] border border-slate-700/70 text-slate-200 shadow-md'
                        : 'bg-cyan-600 text-white shadow-lg shadow-cyan-950/40 rounded-tr-none font-medium'
                    }`}
                  >
                    <p className="whitespace-pre-wrap font-sans">{msg.text}</p>

                    {/* Render Learned Rules Notification if any */}
                    {msg.learnedRules && msg.learnedRules.length > 0 && (
                      <div className="mt-3 pt-2.5 border-t border-slate-700/60 space-y-2">
                        {msg.learnedRules.map((rule, idx) => (
                          <div
                            key={idx}
                            className="bg-emerald-500/10 border border-emerald-500/30 p-2.5 rounded-xl text-xs text-emerald-300 flex items-start gap-2"
                          >
                            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                            <div>
                              <div className="font-bold text-white flex items-center gap-1.5">
                                <span>💡 Yeni Kural Hafızaya Eklendi:</span>
                                <span className="text-emerald-400">{rule.title}</span>
                              </div>
                              <p className="text-[11px] text-slate-300 mt-0.5">{rule.rule}</p>
                              <span className="text-[10px] text-slate-400 font-mono mt-1 block">
                                ➔ Araçlar &gt; Uzman Kuralları menüsünden yönetebilirsiniz.
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Render Interactive Trade Setup Card if present */}
                    {msg.analysisSetup && (
                      <div className="mt-3.5 pt-3 border-t border-slate-700/80 bg-[#10131E] p-3.5 rounded-xl border border-cyan-500/30 shadow-xl space-y-3">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span
                              className={`px-2.5 py-1 rounded-lg text-xs font-black tracking-wider flex items-center gap-1 ${
                                msg.analysisSetup.action === 'BUY'
                                  ? 'bg-emerald-500 text-slate-950'
                                  : msg.analysisSetup.action === 'SELL'
                                  ? 'bg-red-500 text-white'
                                  : 'bg-amber-500 text-slate-950'
                              }`}
                            >
                              {msg.analysisSetup.action === 'BUY' && <TrendingUp className="w-3.5 h-3.5" />}
                              {msg.analysisSetup.action === 'SELL' && <TrendingDown className="w-3.5 h-3.5" />}
                              {msg.analysisSetup.action}
                            </span>
                            <span className="text-xs font-bold text-white font-mono">
                              {msg.analysisSetup.pair} ({msg.analysisSetup.timeframe})
                            </span>
                          </div>

                          {msg.analysisSetup.riskRewardRatio && (
                            <span className="px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/30 text-[10px] font-bold">
                              R:R {msg.analysisSetup.riskRewardRatio}
                            </span>
                          )}
                        </div>

                        {/* Price levels grid */}
                        <div className="grid grid-cols-3 gap-2 text-center">
                          <div className="bg-[#181D2D] p-2 rounded-lg border border-slate-800">
                            <div className="text-[10px] text-slate-400 font-semibold">GİRİŞ</div>
                            <div className="text-xs sm:text-sm font-extrabold text-blue-400 font-mono mt-0.5">
                              {msg.analysisSetup.entryPrice}
                            </div>
                          </div>

                          <div className="bg-red-500/10 p-2 rounded-lg border border-red-500/25">
                            <div className="text-[10px] text-red-300 font-semibold">STOP LOSS (SL)</div>
                            <div className="text-xs sm:text-sm font-extrabold text-red-400 font-mono mt-0.5">
                              {msg.analysisSetup.stopLoss}
                            </div>
                          </div>

                          <div className="bg-emerald-500/10 p-2 rounded-lg border border-emerald-500/25">
                            <div className="text-[10px] text-emerald-300 font-semibold">KÂR AL (TP1)</div>
                            <div className="text-xs sm:text-sm font-extrabold text-emerald-400 font-mono mt-0.5">
                              {msg.analysisSetup.takeProfit1}
                            </div>
                          </div>
                        </div>

                        {/* Support & Resistance zones */}
                        {msg.analysisSetup.zones && msg.analysisSetup.zones.length > 0 && (
                          <div className="bg-[#141824] p-2 rounded-lg border border-slate-800/80 space-y-1">
                            <div className="text-[10px] text-slate-400 font-bold flex items-center gap-1">
                              <Layers className="w-3 h-3 text-cyan-400" />
                              <span>Önemli Destek / Direnç Seviyeleri:</span>
                            </div>
                            <div className="flex flex-wrap gap-1.5">
                              {msg.analysisSetup.zones.map((zone, zIdx) => (
                                <span
                                  key={zIdx}
                                  className={`text-[10px] px-2 py-0.5 rounded border font-mono ${
                                    zone.type === 'support'
                                      ? 'bg-emerald-500/10 text-emerald-300 border-emerald-500/30'
                                      : 'bg-red-500/10 text-red-300 border-red-500/30'
                                  }`}
                                >
                                  {zone.label}: <strong>{zone.price}</strong>
                                </span>
                              ))}
                            </div>
                          </div>
                        )}

                        {/* Trend channel */}
                        {msg.analysisSetup.channel && (
                          <div className="text-[11px] text-slate-300 flex items-center justify-between bg-[#141824] px-2.5 py-1.5 rounded-lg border border-slate-800">
                            <span className="text-slate-400 font-medium">Kanal Yapısı:</span>
                            <span className="font-bold text-purple-400">
                              {msg.analysisSetup.channel.trend} ({msg.analysisSetup.channel.lowerLine} - {msg.analysisSetup.channel.upperLine})
                            </span>
                          </div>
                        )}

                        {/* Highlight on chart button */}
                        <button
                          onClick={() => {
                            if (onAnalysisGenerated && msg.analysisSetup) {
                              onAnalysisGenerated(msg.analysisSetup);
                            }
                          }}
                          className="w-full py-1.5 rounded-lg bg-cyan-600/20 hover:bg-cyan-600/30 text-cyan-300 border border-cyan-500/40 text-xs font-bold transition flex items-center justify-center gap-1.5 active:scale-98"
                        >
                          <Target className="w-3.5 h-3.5" />
                          <span>Bu Seviyeleri Aşağıdaki Grafiğe Yansıt</span>
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}

            {isLoading && (
              <div className="flex items-center gap-2 text-xs text-cyan-400 bg-[#181D2D] p-3 rounded-2xl border border-cyan-500/20 w-fit animate-pulse">
                <Loader2 className="w-4 h-4 animate-spin text-cyan-400" />
                <span>FX Uzmanı grafiği inceliyor ve analiz hazırlıyor...</span>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Quick Prompts Bar */}
          <div className="px-3 py-2 bg-[#101420] border-t border-slate-800/80 flex items-center gap-1.5 overflow-x-auto scrollbar-none">
            {quickPrompts.map((prompt, idx) => (
              <button
                key={idx}
                disabled={isLoading}
                onClick={() => handleSendMessage(prompt)}
                className="px-2.5 py-1 rounded-xl bg-[#181D2E] hover:bg-[#20273D] border border-slate-700/60 text-slate-300 hover:text-white text-[11px] font-medium whitespace-nowrap transition active:scale-95 disabled:opacity-50"
              >
                {prompt}
              </button>
            ))}
          </div>

          {/* Input & Send Form */}
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSendMessage();
            }}
            className="p-3 bg-[#141824] border-t border-slate-800 flex items-center gap-2"
          >
            <input
              type="text"
              placeholder={`${currentSymbol || 'GBPCAD'} hakkında soru sor, seviye iste veya yeni kural söyle...`}
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              disabled={isLoading}
              className="flex-1 bg-[#0F121C] border border-slate-700 rounded-xl px-3.5 py-2.5 text-xs sm:text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-cyan-500 transition"
            />

            <button
              type="submit"
              disabled={!inputText.trim() || isLoading}
              className="p-2.5 rounded-xl bg-cyan-600 hover:bg-cyan-500 disabled:opacity-40 text-white transition active:scale-95 shadow-md shadow-cyan-950/50 shrink-0"
              title="Gönder"
            >
              {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
            </button>
          </form>
        </div>
      )}
    </div>
  );
};
