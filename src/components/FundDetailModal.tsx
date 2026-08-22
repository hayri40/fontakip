import React, { useState, useEffect } from 'react';
import {
  X,
  Star,
  PlusCircle,
  TrendingUp,
  TrendingDown,
  Shield,
  AlertTriangle,
  AlertOctagon,
  BarChart3,
  Activity,
  Layers,
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
} from 'recharts';
import { Fund, HistoryPoint } from '../types';
import { MarketDataService } from '../services/marketData';
import { StorageService } from '../services/storage';
import { AppFormatters } from '../utils/formatters';

interface FundDetailModalProps {
  fund: Fund | null;
  isOpen: boolean;
  onClose: () => void;
  onOpenTransaction: (fundCode: string, currentPrice: number) => void;
}

export const FundDetailModal: React.FC<FundDetailModalProps> = ({
  fund,
  isOpen,
  onClose,
  onOpenTransaction,
}) => {
  const [history, setHistory] = useState<HistoryPoint[]>([]);
  const [loadingHistory, setLoadingHistory] = useState(false);
  const [selectedRange, setSelectedRange] = useState<'1M' | '3M' | '6M' | '1Y'>('1Y');
  const [isFavorite, setIsFavorite] = useState(false);

  useEffect(() => {
    if (fund && isOpen) {
      setIsFavorite(StorageService.getFundFavorites().includes(fund.code));
      setLoadingHistory(true);
      MarketDataService.getFundHistory(fund.code, fund.currentPrice)
        .then((data) => {
          setHistory(data);
          setLoadingHistory(false);
        })
        .catch(() => setLoadingHistory(false));
    }
  }, [fund, isOpen]);

  if (!isOpen || !fund) return null;

  const toggleFav = () => {
    const nextState = StorageService.toggleFundFavorite(fund.code);
    setIsFavorite(nextState);
  };

  // Filter history based on range
  const getFilteredHistory = () => {
    if (history.length === 0) return [];
    let sliceDays = 365;
    if (selectedRange === '1M') sliceDays = 30;
    else if (selectedRange === '3M') sliceDays = 90;
    else if (selectedRange === '6M') sliceDays = 180;
    
    return history.slice(-sliceDays);
  };

  const filteredHistory = getFilteredHistory();
  const firstPrice = filteredHistory[0]?.price || fund.currentPrice;
  const periodReturn = firstPrice > 0 ? ((fund.currentPrice - firstPrice) / firstPrice) * 100 : 0;
  const isPositive = periodReturn >= 0;

  const getRiskBadge = (score: number) => {
    if (score <= 2) {
      return {
        label: 'Düşük Risk (1-2)',
        color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30',
        icon: Shield,
      };
    }
    if (score <= 4) {
      return {
        label: 'Orta Risk (3-4)',
        color: 'text-amber-400 bg-amber-500/10 border-amber-500/30',
        icon: AlertTriangle,
      };
    }
    return {
      label: 'Yüksek Risk (5-7)',
      color: 'text-red-400 bg-red-500/10 border-red-500/30',
      icon: AlertOctagon,
    };
  };

  const riskInfo = getRiskBadge(fund.riskScore);
  const RiskIcon = riskInfo.icon;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200">
      <div className="bg-[#141824] border border-slate-700/80 rounded-2xl w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="p-4 sm:p-5 border-b border-slate-800 bg-[#10131D] flex items-start justify-between gap-3">
          <div className="flex items-start gap-3">
            <div className="w-12 h-12 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400 font-extrabold text-lg">
              {fund.code}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-white text-base sm:text-lg">{fund.code}</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                  {fund.category}
                </span>
              </div>
              <h2 className="text-xs sm:text-sm text-slate-300 font-medium line-clamp-2 mt-0.5">
                {fund.name}
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

        {/* Modal Body */}
        <div className="p-4 sm:p-6 overflow-y-auto space-y-5">
          {/* Main Price & Performance Banner */}
          <div className="flex flex-wrap items-baseline justify-between gap-4 p-4 rounded-xl bg-[#181D2B] border border-slate-800">
            <div>
              <div className="text-xs text-slate-400 font-medium mb-1">Güncel Pay Fiyatı</div>
              <div className="text-2xl sm:text-3xl font-extrabold text-white font-mono">
                {AppFormatters.currency(fund.currentPrice)}
              </div>
            </div>

            <div className="text-right">
              <div className="text-xs text-slate-400 font-medium mb-1">1 Yıllık Nominal Getiri</div>
              <div
                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-sm sm:text-base font-bold ${
                  fund.return1Y >= 0 ? 'bg-emerald-500/15 text-emerald-400' : 'bg-red-500/15 text-red-400'
                }`}
              >
                {fund.return1Y >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
                {AppFormatters.signedPercent(fund.return1Y)}
              </div>
            </div>
          </div>

          {/* Time Range Selector & Chart */}
          <div className="p-4 rounded-xl bg-[#181D2B] border border-slate-800">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-cyan-400" />
                <span className="text-xs sm:text-sm font-semibold text-slate-200">Fiyat Grafiği & Trend</span>
                <span
                  className={`text-xs font-bold px-2 py-0.5 rounded ${
                    isPositive ? 'text-emerald-400 bg-emerald-500/10' : 'text-red-400 bg-red-500/10'
                  }`}
                >
                  {AppFormatters.signedPercent(periodReturn)}
                </span>
              </div>

              {/* Range Buttons */}
              <div className="flex items-center gap-1 bg-[#10131B] p-1 rounded-lg border border-slate-700/80">
                {(['1M', '3M', '6M', '1Y'] as const).map((range) => (
                  <button
                    key={range}
                    onClick={() => setSelectedRange(range)}
                    className={`px-2.5 py-1 text-xs font-semibold rounded-md transition ${
                      selectedRange === range
                        ? 'bg-cyan-500 text-slate-950 shadow-sm'
                        : 'text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    {range}
                  </button>
                ))}
              </div>
            </div>

            {/* Chart Area */}
            <div className="h-56 w-full">
              {loadingHistory ? (
                <div className="h-full flex items-center justify-center text-slate-400 text-sm">
                  Grafik verisi yükleniyor...
                </div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={filteredHistory}>
                    <defs>
                      <linearGradient id="fundGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={isPositive ? '#10B981' : '#EF4444'} stopOpacity={0.4} />
                        <stop offset="95%" stopColor={isPositive ? '#10B981' : '#EF4444'} stopOpacity={0.0} />
                      </linearGradient>
                    </defs>
                    <XAxis
                      dataKey="date"
                      tickFormatter={(val) => {
                        const parts = val.split('-');
                        return `${parts[2]}/${parts[1]}`;
                      }}
                      stroke="#475569"
                      fontSize={11}
                      tickLine={false}
                      axisLine={false}
                    />
                    <YAxis
                      domain={['dataMin', 'dataMax']}
                      tickFormatter={(v) => v.toFixed(2)}
                      stroke="#475569"
                      fontSize={11}
                      tickLine={false}
                      axisLine={false}
                      orientation="right"
                    />
                    <Tooltip
                      content={({ active, payload }) => {
                        if (active && payload && payload.length) {
                          const data = payload[0].payload as HistoryPoint;
                          return (
                            <div className="bg-[#10131D] border border-slate-700 p-2.5 rounded-lg shadow-xl text-xs">
                              <p className="text-slate-400 font-medium">{AppFormatters.date(data.date)}</p>
                              <p className="text-white font-bold font-mono text-sm mt-0.5">
                                {AppFormatters.currency(data.price)}
                              </p>
                            </div>
                          );
                        }
                        return null;
                      }}
                    />
                    <Area
                      type="monotone"
                      dataKey="price"
                      stroke={isPositive ? '#10B981' : '#EF4444'}
                      strokeWidth={2}
                      fillOpacity={1}
                      fill="url(#fundGradient)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>

          {/* Key Metrics Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {/* Risk Score */}
            <div className="p-3.5 rounded-xl bg-[#181D2B] border border-slate-800 flex items-center gap-3">
              <div className={`p-2.5 rounded-xl border ${riskInfo.color}`}>
                <RiskIcon className="w-5 h-5" />
              </div>
              <div>
                <div className="text-[11px] text-slate-400 font-medium">Risk Seviyesi</div>
                <div className="text-sm font-bold text-white">{fund.riskScore} / 7</div>
                <div className="text-[10px] text-slate-400">{riskInfo.label}</div>
              </div>
            </div>

            {/* Real Return */}
            <div className="p-3.5 rounded-xl bg-[#181D2B] border border-slate-800 flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
                <Activity className="w-5 h-5" />
              </div>
              <div>
                <div className="text-[11px] text-slate-400 font-medium">1Y Reel Getiri (Enf. Üstü)</div>
                <div className="text-sm font-bold text-emerald-400">
                  {AppFormatters.signedPercent(fund.realReturn1Y)}
                </div>
                <div className="text-[10px] text-slate-400">TÜFE arındırılmış</div>
              </div>
            </div>

            {/* Sharpe Ratio */}
            <div className="p-3.5 rounded-xl bg-[#181D2B] border border-slate-800 flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-cyan-500/10 border border-cyan-500/20 text-cyan-400">
                <Layers className="w-5 h-5" />
              </div>
              <div>
                <div className="text-[11px] text-slate-400 font-medium">Sharpe Oranı (90 Gün)</div>
                <div className="text-sm font-bold text-cyan-400">{fund.sharpe90.toFixed(2)}</div>
                <div className="text-[10px] text-slate-400">Risk başı getiri kalitesi</div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-slate-800 bg-[#10131D] flex items-center gap-3">
          <button
            onClick={() => {
              onClose();
              onOpenTransaction(fund.code, fund.currentPrice);
            }}
            className="flex-1 py-3 px-4 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold text-sm transition flex items-center justify-center gap-2 shadow-lg shadow-cyan-500/20"
          >
            <PlusCircle className="w-4 h-4" />
            İşlem Ekle (Al / Sat)
          </button>
        </div>
      </div>
    </div>
  );
};
