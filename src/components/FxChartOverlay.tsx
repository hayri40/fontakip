import React from 'react';
import {
  Target,
  TrendingUp,
  TrendingDown,
  Shield,
  Layers,
  X,
  Sparkles,
  ArrowUpRight,
  ArrowDownRight,
  Maximize2,
  Minimize2,
} from 'lucide-react';
import { ExpertAnalysisSetup } from '../types';

interface FxChartOverlayProps {
  setup: ExpertAnalysisSetup | null;
  onClear: () => void;
}

export const FxChartOverlay: React.FC<FxChartOverlayProps> = ({ setup, onClear }) => {
  if (!setup) return null;

  const isBuy = setup.action === 'BUY';
  const isSell = setup.action === 'SELL';

  return (
    <div className="absolute top-2 left-2 right-2 z-20 pointer-events-none flex flex-col gap-2">
      {/* Top Floating HUD Pill Bar */}
      <div className="pointer-events-auto bg-[#101420]/95 backdrop-blur-md border border-cyan-500/30 shadow-2xl rounded-2xl p-2.5 sm:px-4 sm:py-2.5 flex flex-wrap items-center justify-between gap-2.5 text-xs animate-in slide-in-from-top-2 duration-200">
        {/* Left: Action & Symbol */}
        <div className="flex items-center gap-2">
          <div
            className={`px-2.5 py-1 rounded-xl font-black text-xs tracking-wider flex items-center gap-1 shadow-md ${
              isBuy
                ? 'bg-emerald-500 text-slate-950'
                : isSell
                ? 'bg-red-500 text-white'
                : 'bg-amber-500 text-slate-950'
            }`}
          >
            {isBuy && <TrendingUp className="w-3.5 h-3.5" />}
            {isSell && <TrendingDown className="w-3.5 h-3.5" />}
            <span>{setup.action}</span>
          </div>

          <div className="font-bold text-white font-mono flex items-center gap-1.5">
            <span>{setup.pair}</span>
            <span className="text-slate-500">•</span>
            <span className="text-cyan-400">{setup.timeframe}</span>
          </div>

          {setup.riskRewardRatio && (
            <span className="hidden sm:inline-block px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/30 text-[10px] font-bold">
              R:R {setup.riskRewardRatio}
            </span>
          )}
        </div>

        {/* Center: Price Levels (Giriş, TP, SL) */}
        <div className="flex items-center gap-2 font-mono text-[11px] sm:text-xs">
          {/* Giriş */}
          <div className="bg-[#181D2D] px-2.5 py-1 rounded-lg border border-slate-700/80 flex items-center gap-1.5">
            <span className="text-slate-400 font-sans font-semibold text-[10px]">GİRİŞ:</span>
            <span className="text-blue-400 font-extrabold">{setup.entryPrice}</span>
          </div>

          {/* TP1 */}
          <div className="bg-emerald-500/15 px-2.5 py-1 rounded-lg border border-emerald-500/30 flex items-center gap-1.5 text-emerald-300">
            <span className="font-sans font-semibold text-[10px]">TP:</span>
            <span className="font-extrabold text-emerald-400">{setup.takeProfit1}</span>
          </div>

          {/* SL */}
          <div className="bg-red-500/15 px-2.5 py-1 rounded-lg border border-red-500/30 flex items-center gap-1.5 text-red-300">
            <span className="font-sans font-semibold text-[10px]">SL:</span>
            <span className="font-extrabold text-red-400">{setup.stopLoss}</span>
          </div>
        </div>

        {/* Right: Close Overlay */}
        <div className="flex items-center gap-1.5">
          <button
            onClick={onClear}
            className="p-1 rounded-lg bg-slate-800/80 hover:bg-red-900/50 text-slate-400 hover:text-white transition"
            title="İşaretleri Grafikten Kaldır"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Support / Resistance Sub-strip (if available) */}
      {setup.zones && setup.zones.length > 0 && (
        <div className="pointer-events-auto bg-[#101420]/90 backdrop-blur-sm border border-slate-800 px-3 py-1.5 rounded-xl flex items-center gap-2 overflow-x-auto scrollbar-none w-fit max-w-full">
          <span className="text-[10px] text-slate-400 font-semibold flex items-center gap-1 shrink-0">
            <Layers className="w-3 h-3 text-cyan-400" />
            Bölgeler:
          </span>
          {setup.zones.map((zone, idx) => (
            <span
              key={idx}
              className={`text-[10px] px-2 py-0.5 rounded border font-mono whitespace-nowrap ${
                zone.type === 'support'
                  ? 'bg-emerald-500/10 text-emerald-300 border-emerald-500/30'
                  : 'bg-red-500/10 text-red-300 border-red-500/30'
              }`}
            >
              {zone.label}: <strong>{zone.price}</strong>
            </span>
          ))}
          {setup.channel && (
            <span className="text-[10px] px-2 py-0.5 rounded border border-purple-500/30 bg-purple-500/10 text-purple-300 font-mono whitespace-nowrap">
              Kanal: {setup.channel.trend}
            </span>
          )}
        </div>
      )}
    </div>
  );
};
