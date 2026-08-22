import React, { useEffect, useState } from 'react';
import {
  Maximize2,
  Minimize2,
  ExternalLink,
  Server,
  Info,
  Layers,
  Sparkles,
  TrendingUp,
} from 'lucide-react';
import { FxExpertChat } from '../components/FxExpertChat';
import { FxChartOverlay } from '../components/FxChartOverlay';
import { ExpertAnalysisSetup } from '../types';

declare global {
  interface Window {
    TradingView?: any;
  }
}

export const FxScreen: React.FC = () => {
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [activeAnalysisSetup, setActiveAnalysisSetup] = useState<ExpertAnalysisSetup | null>(null);

  // MT5 WebTerminal state
  const [selectedServer, setSelectedServer] = useState<string>(() => {
    return localStorage.getItem('mt5_server') || 'XMGlobal-MT5 9';
  });
  const [customServer, setCustomServer] = useState<string>('');
  const [isCustomMode, setIsCustomMode] = useState<boolean>(false);
  const [terminalVersion, setTerminalVersion] = useState<'5' | '4'>('5');

  const currentSymbol = 'GBPCAD';
  const currentTimeframe = '1H';
  const widgetContainerId = 'tradingview_advanced_full_widget';

  useEffect(() => {
    let script = document.getElementById('tradingview-widget-script') as HTMLScriptElement | null;

    const initWidget = () => {
      if (window.TradingView && document.getElementById(widgetContainerId)) {
        const el = document.getElementById(widgetContainerId);
        if (el) el.innerHTML = '';

        new window.TradingView.widget({
          autosize: true,
          symbol: `FX:${currentSymbol}`,
          interval: '60',
          timezone: 'Europe/Istanbul',
          theme: 'dark',
          style: '1',
          locale: 'tr',
          toolbar_bg: '#161922',
          enable_publishing: false,
          allow_symbol_change: true,
          container_id: widgetContainerId,
          hide_side_toolbar: false,
          withdateranges: true,
          save_image: true,
          details: true,
          hotlist: true,
          calendar: true,
          show_popup_button: false,
          news: ['headlines'],
          studies: ['STD;SMA', 'STD;RSI', 'STD;MACD'],
          overrides: {
            'paneProperties.background': '#131722',
            'paneProperties.vertGridProperties.color': '#1E222D',
            'paneProperties.horzGridProperties.color': '#1E222D',
            'symbolWatermarkProperties.transparency': 90,
            'scalesProperties.textColor': '#94A3B8',
          },
        });
      }
    };

    if (!window.TradingView) {
      if (!script) {
        script = document.createElement('script');
        script.id = 'tradingview-widget-script';
        script.src = 'https://s3.tradingview.com/tv.js';
        script.type = 'text/javascript';
        script.async = true;
        script.onload = initWidget;
        document.body.appendChild(script);
      } else {
        script.addEventListener('load', initWidget);
      }
    } else {
      initWidget();
    }
  }, [currentSymbol]);

  const activeServer = isCustomMode && customServer.trim() ? customServer.trim() : selectedServer;

  const handleServerChange = (srv: string) => {
    setSelectedServer(srv);
    setIsCustomMode(false);
    localStorage.setItem('mt5_server', srv);
  };

  const mt5ServersList = [
    'XMGlobal-MT5 9',
    'XMGlobal-MT5',
    'XMGlobal-MT5 2',
    'XMGlobal-MT5 3',
    'XMGlobal-MT5 4',
    'XMGlobal-MT5 5',
    'XMGlobal-MT5 6',
    'XMGlobal-MT5 7',
    'XMGlobal-MT5 8',
    'XMGlobal-MT5 10',
    'MetaQuotes-Demo',
  ];

  const mt4ServersList = [
    'XMGlobal-Real 1',
    'XMGlobal-Real 2',
    'XMGlobal-Real 3',
    'XMGlobal-Real 4',
    'XMGlobal-Real 5',
    'XMGlobal-Real 6',
    'XMGlobal-Real 7',
    'XMGlobal-Real 8',
    'XMGlobal-Demo',
  ];

  const serverListToUse = terminalVersion === '5' ? mt5ServersList : mt4ServersList;
  const serversQuery = [activeServer, ...serverListToUse].filter((v, i, a) => a.indexOf(v) === i).join(',');

  const webTerminalUrl =
    terminalVersion === '5'
      ? `https://metatraderweb.app/trade?servers=${encodeURIComponent(
          serversQuery
        )}&trade_server=${encodeURIComponent(activeServer)}&lang=tr`
      : `https://trade.mql5.com/trade?servers=${encodeURIComponent(
          serversQuery
        )}&trade_server=${encodeURIComponent(activeServer)}&lang=tr`;

  const xmOfficialWebtraderUrl = `https://webtrader.xm.com/`;

  return (
    <div
      className={`space-y-4 pb-10 ${
        isFullscreen
          ? 'fixed inset-0 z-50 bg-[#0F1117] p-3 overflow-y-auto'
          : 'flex-1 flex flex-col min-h-0'
      }`}
    >
      {/* 1. UZMAN FX SOHBET & ANALİZ EKRANI (KARTIN ÜSTÜNDE) */}
      <FxExpertChat
        currentSymbol={currentSymbol}
        currentTimeframe={currentTimeframe}
        onAnalysisGenerated={(setup) => setActiveAnalysisSetup(setup)}
        activeAnalysisSetup={activeAnalysisSetup}
      />

      {/* 2. TRADINGVIEW GRAFİK KARTI (Üzerinde Uzman Çizim & Seviye Katmanı ile) */}
      <div className="bg-[#131722] border border-slate-800 rounded-2xl overflow-hidden shadow-2xl relative h-[440px] sm:h-[500px] shrink-0">
        {/* Fullscreen Toggle Header Corner */}
        <div className="absolute top-3 right-3 z-30 flex items-center gap-2">
          <button
            onClick={() => setIsFullscreen(!isFullscreen)}
            className="p-2 rounded-xl bg-slate-900/90 hover:bg-slate-800 text-slate-300 hover:text-white text-xs font-semibold border border-slate-700/80 backdrop-blur-md shadow-lg flex items-center gap-1.5 transition active:scale-95"
            title={isFullscreen ? 'Küçült' : 'Tam Ekran Grafiğe Geç'}
          >
            {isFullscreen ? <Minimize2 className="w-3.5 h-3.5" /> : <Maximize2 className="w-3.5 h-3.5" />}
            <span className="hidden sm:inline">{isFullscreen ? 'Normal Görünüm' : 'Tam Ekran'}</span>
          </button>
        </div>

        {/* Canlı Grafik Analiz Seviyeleri (Giriş, TP, SL, Bölgeler) HUD Katmanı */}
        <FxChartOverlay setup={activeAnalysisSetup} onClear={() => setActiveAnalysisSetup(null)} />

        {/* TradingView Chart Container */}
        <div id={widgetContainerId} className="w-full h-full min-h-0" />
      </div>

      {/* 3. METATRADER 5 / XM İŞLEM VE TERMİNAL KARTI */}
      <div className="bg-[#161922] border border-slate-800 rounded-2xl overflow-hidden shadow-2xl flex flex-col min-h-[520px]">
        {/* Terminal Header & Server Switcher */}
        <div className="bg-[#1A1D24] border-b border-slate-800 p-3 sm:px-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-red-600 flex items-center justify-center font-black text-white text-xs shadow-md">
              XM
            </div>
            <div>
              <div className="text-xs sm:text-sm font-bold text-white flex items-center gap-2">
                <span>MetaTrader 5 & FX İşlem Terminali</span>
                <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                  Gerçek Hesap
                </span>
              </div>
              <div className="text-[11px] text-slate-400 flex items-center gap-1.5 font-mono mt-0.5">
                <Server className="w-3 h-3 text-red-400" />
                <span>Aktif Sunucu:</span>
                <span className="text-red-400 font-bold">{activeServer}</span>
              </div>
            </div>
          </div>

          {/* Controls */}
          <div className="flex items-center flex-wrap gap-2">
            <div className="flex items-center gap-1.5 bg-[#0F1117] p-1 rounded-xl border border-slate-800">
              <div className="flex items-center bg-[#161922] p-0.5 rounded-lg border border-slate-700">
                <button
                  onClick={() => {
                    setTerminalVersion('5');
                    setSelectedServer('XMGlobal-MT5 9');
                  }}
                  className={`px-2 py-1 rounded text-xs font-bold transition ${
                    terminalVersion === '5' ? 'bg-red-600 text-white' : 'text-slate-400 hover:text-white'
                  }`}
                >
                  MT5
                </button>
                <button
                  onClick={() => {
                    setTerminalVersion('4');
                    setSelectedServer('XMGlobal-Real 1');
                  }}
                  className={`px-2 py-1 rounded text-xs font-bold transition ${
                    terminalVersion === '4' ? 'bg-red-600 text-white' : 'text-slate-400 hover:text-white'
                  }`}
                >
                  MT4
                </button>
              </div>

              <span className="text-[10px] text-slate-400 px-1 font-semibold">Sunucu:</span>
              <select
                value={isCustomMode ? 'custom' : selectedServer}
                onChange={(e) => {
                  if (e.target.value === 'custom') {
                    setIsCustomMode(true);
                  } else {
                    handleServerChange(e.target.value);
                  }
                }}
                className="bg-[#161922] text-xs text-white border border-slate-700 rounded-lg px-2 py-1 focus:outline-none focus:border-red-500 font-mono"
              >
                {serverListToUse.map((srv) => (
                  <option key={srv} value={srv}>
                    {srv}
                  </option>
                ))}
                <option value="custom">✏️ Diğer Sunucu Yaz...</option>
              </select>
            </div>

            {isCustomMode && (
              <div className="flex items-center gap-1">
                <input
                  type="text"
                  placeholder="Örn: XMGlobal-MT5 9"
                  value={customServer}
                  onChange={(e) => setCustomServer(e.target.value)}
                  className="px-2.5 py-1 bg-[#0F1117] border border-red-500/60 rounded-lg text-xs text-white focus:outline-none w-36"
                />
              </div>
            )}

            <a
              href={webTerminalUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 rounded-xl bg-red-600/20 hover:bg-red-600/30 text-red-300 hover:text-red-200 text-xs font-semibold border border-red-500/40 flex items-center gap-1.5 transition active:scale-95"
              title="MQL5 Web Terminalini Yeni Sekmede Aç"
            >
              <ExternalLink className="w-3.5 h-3.5" />
              <span>Sekmede Aç</span>
            </a>

            <a
              href={xmOfficialWebtraderUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-xs font-medium border border-slate-700 flex items-center gap-1.5 transition active:scale-95"
              title="Resmi XM WebTrader Portalı"
            >
              <ExternalLink className="w-3.5 h-3.5" />
              <span>XM WebTrader</span>
            </a>
          </div>
        </div>

        {/* Gerçek Hesap Giriş İpucu Banner'ı */}
        <div className="bg-gradient-to-r from-blue-950/40 via-slate-900 to-red-950/30 border-b border-slate-800 px-4 py-2 text-[11px] text-slate-300 flex items-center gap-2">
          <Info className="w-4 h-4 text-cyan-400 shrink-0" />
          <div className="flex-1">
            <span className="font-semibold text-white">İşlem Hesabı Girişi:</span> Aşağıdaki terminalde{' '}
            <strong className="text-white">"İşlem Hesabına Giriş"</strong> penceresinde{' '}
            <strong>Sunucu (Server)</strong> kısmına kendi sunucu adınızı (örn:{' '}
            <code className="bg-slate-800 px-1 py-0.2 rounded text-red-300">{activeServer}</code>) seçebilir veya doğrudan yazabilirsiniz.
          </div>
        </div>

        {/* MT5 Web Terminal Iframe Container */}
        <div className="flex-1 w-full bg-[#1e222d] min-h-[500px] relative">
          <iframe
            key={`${terminalVersion}-${activeServer}`}
            title="MetaTrader 5 Web Terminal"
            src={webTerminalUrl}
            className="w-full h-full min-h-[500px] border-0"
            allow="fullscreen; clipboard-read; clipboard-write; camera; microphone; payment"
          />
        </div>
      </div>
    </div>
  );
};
