import React, { useState } from 'react';
import {
  X,
  Star,
  PlusCircle,
  TrendingUp,
  TrendingDown,
  Building2,
  PieChart,
  DollarSign,
  Maximize2,
} from 'lucide-react';
import { Stock } from '../types';
import { StorageService } from '../services/storage';
import { AppFormatters } from '../utils/formatters';

interface StockDetailModalProps {
  stock: Stock | null;
  isOpen: boolean;
  onClose: () => void;
  onOpenTransaction: (symbol: string, currentPrice: number) => void;
}

export const StockDetailModal: React.FC<StockDetailModalProps> = ({
  stock,
  isOpen,
  onClose,
  onOpenTransaction,
}) => {
  const [isFavorite, setIsFavorite] = useState(false);

  React.useEffect(() => {
    if (stock && isOpen) {
      setIsFavorite(StorageService.getStockFavorites().includes(stock.symbol));
    }
  }, [stock, isOpen]);

  if (!isOpen || !stock) return null;

  const toggleFav = () => {
    const nextState = StorageService.toggleStockFavorite(stock.symbol);
    setIsFavorite(nextState);
  };

  const isPositive = (stock.changePercent ?? 0) >= 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200">
      <div className="bg-[#141824] border border-slate-700/80 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 sm:p-5 border-b border-slate-800 bg-[#10131D] flex items-start justify-between gap-3">
          <div className="flex items-start gap-3">
            <div className="w-12 h-12 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400 font-extrabold text-base">
              {stock.symbol}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-white text-lg">{stock.symbol}</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                  {stock.sector}
                </span>
              </div>
              <h2 className="text-xs sm:text-sm text-slate-300 font-medium line-clamp-1 mt-0.5">
                {stock.name}
              </h2>
            </div>
          </div>

          <div className="flex items-center gap-1">
            <button
              onClick={toggleFav}
              className={`p-2 rounded-xl border transition ${
                isFavorite
                  ? 'bg-amber-500/20 border-amber-500/40 text-amber-400'
                  : 'bg-slate-800/60 border-slate-700 text-slate-400 hover:text-slate-200'
              }`}
              title="Favorilere Ekle/Çıkar"
            >
              <Star className={`w-5 h-5 ${isFavorite ? 'fill-amber-400' : ''}`} />
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-xl bg-slate-800/60 border border-slate-700 text-slate-400 hover:text-white transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-4 sm:p-6 space-y-4">
          {/* Price & Change Banner */}
          <div className="flex items-baseline justify-between p-4 rounded-xl bg-[#181D2B] border border-slate-800">
            <div>
              <div className="text-xs text-slate-400 font-medium mb-1">Son Fiyat</div>
              <div className="text-2xl sm:text-3xl font-extrabold text-white font-mono">
                {AppFormatters.currency(stock.currentPrice)}
              </div>
            </div>

            <div className="text-right">
              <div className="text-xs text-slate-400 font-medium mb-1">Günlük Değişim</div>
              <div
                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-sm sm:text-base font-bold ${
                  isPositive ? 'bg-emerald-500/15 text-emerald-400' : 'bg-red-500/15 text-red-400'
                }`}
              >
                {isPositive ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
                {AppFormatters.signedPercent(stock.changePercent)}
              </div>
            </div>
          </div>

          {/* Daily Range Bar */}
          {stock.dayLow && stock.dayHigh && (
            <div className="p-4 rounded-xl bg-[#181D2B] border border-slate-800 space-y-2">
              <div className="flex justify-between text-xs text-slate-400 font-medium">
                <span>Gün İçi En Düşük</span>
                <span>Gün İçi En Yüksek</span>
              </div>
              <div className="flex justify-between text-xs font-mono font-bold text-slate-200">
                <span>{AppFormatters.currency(stock.dayLow)}</span>
                <span>{AppFormatters.currency(stock.dayHigh)}</span>
              </div>
              <div className="w-full h-2 bg-slate-800 rounded-full overflow-hidden relative">
                <div
                  className="absolute top-0 bottom-0 bg-gradient-to-r from-emerald-500 to-cyan-500 rounded-full"
                  style={{
                    left: `${Math.max(
                      0,
                      Math.min(
                        100,
                        ((stock.currentPrice - stock.dayLow) / (stock.dayHigh - stock.dayLow || 1)) * 100
                      )
                    )}%`,
                    width: '6px',
                    transform: 'translateX(-50%)',
                  }}
                />
              </div>
            </div>
          )}

          {/* Financials Grid */}
          <div className="grid grid-cols-2 gap-3">
            <div className="p-3 rounded-xl bg-[#181D2B] border border-slate-800">
              <div className="text-[11px] text-slate-400 font-medium">Piyasa Değeri</div>
              <div className="text-sm font-bold text-white mt-0.5">{stock.marketCap || '-'}</div>
            </div>

            <div className="p-3 rounded-xl bg-[#181D2B] border border-slate-800">
              <div className="text-[11px] text-slate-400 font-medium">Fiyat / Kazanç (F/K)</div>
              <div className="text-sm font-bold text-cyan-400 mt-0.5">
                {stock.peRatio ? stock.peRatio.toFixed(2) : '-'}
              </div>
            </div>

            <div className="p-3 rounded-xl bg-[#181D2B] border border-slate-800">
              <div className="text-[11px] text-slate-400 font-medium">Hisse Başına Kar (EPS)</div>
              <div className="text-sm font-bold text-emerald-400 mt-0.5">
                {stock.eps ? AppFormatters.currency(stock.eps) : '-'}
              </div>
            </div>

            <div className="p-3 rounded-xl bg-[#181D2B] border border-slate-800">
              <div className="text-[11px] text-slate-400 font-medium">Önceki Kapanış</div>
              <div className="text-sm font-bold text-slate-200 mt-0.5">
                {AppFormatters.currency(stock.previousClose)}
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-slate-800 bg-[#10131D]">
          <button
            onClick={() => {
              onClose();
              onOpenTransaction(stock.symbol, stock.currentPrice);
            }}
            className="w-full py-3 px-4 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold text-sm transition flex items-center justify-center gap-2 shadow-lg shadow-cyan-500/20"
          >
            <PlusCircle className="w-4 h-4" />
            İşlem Ekle (Al / Sat)
          </button>
        </div>
      </div>
    </div>
  );
};
