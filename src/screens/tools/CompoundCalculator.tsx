import React, { useState } from 'react';
import {
  Calculator,
  TrendingUp,
  DollarSign,
  PiggyBank,
  Layers,
  Sparkles,
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
} from 'recharts';
import { AppFormatters } from '../../utils/formatters';

interface YearRow {
  year: number;
  totalInvested: number;
  totalValue: number;
  interestEarned: number;
}

export const CompoundCalculator: React.FC = () => {
  const [initialCapital, setInitialCapital] = useState('50000');
  const [monthlyDeposit, setMonthlyDeposit] = useState('5000');
  const [annualRate, setAnnualRate] = useState('45'); // 45% annual return
  const [years, setYears] = useState('5');

  const p0 = parseFloat(initialCapital.replace(',', '.')) || 0;
  const pMonthly = parseFloat(monthlyDeposit.replace(',', '.')) || 0;
  const rAnnual = (parseFloat(annualRate.replace(',', '.')) || 0) / 100;
  const nYears = Math.min(40, Math.max(1, parseInt(years) || 1));

  // Monthly compound calculation
  const rMonthly = Math.pow(1 + rAnnual, 1 / 12) - 1;
  const totalMonths = nYears * 12;

  const yearData: YearRow[] = [];
  let currentValue = p0;
  let totalInvested = p0;

  for (let m = 1; m <= totalMonths; m++) {
    currentValue = currentValue * (1 + rMonthly) + pMonthly;
    totalInvested += pMonthly;

    if (m % 12 === 0 || m === totalMonths) {
      const yr = Math.ceil(m / 12);
      yearData.push({
        year: yr,
        totalInvested: Math.round(totalInvested),
        totalValue: Math.round(currentValue),
        interestEarned: Math.round(currentValue - totalInvested),
      });
    }
  }

  const finalValue = currentValue;
  const finalInvested = totalInvested;
  const totalGain = finalValue - finalInvested;
  const totalGainPercent = finalInvested > 0 ? (totalGain / finalInvested) * 100 : 0;

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Inputs Form Card */}
      <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
        <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
          <Calculator className="w-4 h-4 text-cyan-400" />
          Hesaplama Parametreleri
        </h4>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs text-slate-400 font-medium mb-1.5">
              Başlangıç Ana Parası (₺)
            </label>
            <input
              type="number"
              value={initialCapital}
              onChange={(e) => setInitialCapital(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
            />
          </div>

          <div>
            <label className="block text-xs text-slate-400 font-medium mb-1.5">
              Aylık Düzenli Eklenen Tutar (₺)
            </label>
            <input
              type="number"
              value={monthlyDeposit}
              onChange={(e) => setMonthlyDeposit(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
            />
          </div>

          <div>
            <label className="block text-xs text-slate-400 font-medium mb-1.5">
              Yıllık Beklenen Getiri Oranı (%)
            </label>
            <input
              type="number"
              value={annualRate}
              onChange={(e) => setAnnualRate(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
            />
          </div>

          <div>
            <label className="block text-xs text-slate-400 font-medium mb-1.5">
              Yatırım Süresi (Yıl)
            </label>
            <input
              type="number"
              min="1"
              max="40"
              value={years}
              onChange={(e) => setYears(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
            />
          </div>
        </div>
      </div>

      {/* Summary Highlight Banner */}
      <div className="p-6 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 shadow-xl space-y-4">
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold text-cyan-400 uppercase tracking-wider flex items-center gap-1.5">
            <Sparkles className="w-4 h-4" />
            {nYears} Yıl Sonraki Tahmini Portföy Büyüklüğü
          </span>
        </div>

        <div className="text-3xl sm:text-4xl font-extrabold text-white font-mono">
          {AppFormatters.currency(finalValue)}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-3 border-t border-slate-800">
          <div className="p-3 rounded-xl bg-[#11141E] border border-slate-800">
            <div className="text-[11px] text-slate-400">Toplam Yatırılan Ana Para</div>
            <div className="text-base font-bold text-slate-200 font-mono mt-0.5">
              {AppFormatters.currency(finalInvested)}
            </div>
          </div>

          <div className="p-3 rounded-xl bg-[#11141E] border border-emerald-500/20">
            <div className="text-[11px] text-emerald-400">Kazanılan Bileşik Getiri</div>
            <div className="text-base font-bold text-emerald-400 font-mono mt-0.5">
              +{AppFormatters.currency(totalGain)}
            </div>
          </div>

          <div className="p-3 rounded-xl bg-[#11141E] border border-cyan-500/20">
            <div className="text-[11px] text-cyan-400">Toplam Getiri Yüzdesi</div>
            <div className="text-base font-bold text-cyan-400 font-mono mt-0.5">
              {AppFormatters.signedPercent(totalGainPercent)}
            </div>
          </div>
        </div>
      </div>

      {/* Growth Area Chart */}
      <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
        <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
          Portföy Büyüme Eğrisi & Bileşik Getiri Etkisi
        </h4>

        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={yearData}>
              <defs>
                <linearGradient id="totalValueGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#06B6D4" stopOpacity={0.4} />
                  <stop offset="95%" stopColor="#06B6D4" stopOpacity={0.0} />
                </linearGradient>
                <linearGradient id="investedGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#64748B" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#64748B" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <XAxis
                dataKey="year"
                tickFormatter={(y) => `${y}. Yıl`}
                stroke="#475569"
                fontSize={11}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                stroke="#475569"
                fontSize={11}
                tickFormatter={(v) => `${(v / 1000).toFixed(0)}k ₺`}
                tickLine={false}
                axisLine={false}
                orientation="right"
              />
              <Tooltip
                content={({ active, payload }) => {
                  if (active && payload && payload.length) {
                    const row = payload[0].payload as YearRow;
                    return (
                      <div className="bg-[#10131D] border border-slate-700 p-3 rounded-xl shadow-xl text-xs space-y-1">
                        <p className="text-cyan-400 font-bold">{row.year}. Yıl Sonu</p>
                        <p className="text-white font-mono">
                          Toplam Değer: {AppFormatters.currency(row.totalValue)}
                        </p>
                        <p className="text-slate-400 font-mono">
                          Yatırılan: {AppFormatters.currency(row.totalInvested)}
                        </p>
                        <p className="text-emerald-400 font-mono">
                          Bileşik Kar: {AppFormatters.currency(row.interestEarned)}
                        </p>
                      </div>
                    );
                  }
                  return null;
                }}
              />
              <Area
                type="monotone"
                dataKey="totalValue"
                stroke="#06B6D4"
                strokeWidth={2}
                fillOpacity={1}
                fill="url(#totalValueGrad)"
                name="Toplam Portföy"
              />
              <Area
                type="monotone"
                dataKey="totalInvested"
                stroke="#64748B"
                strokeWidth={1.5}
                strokeDasharray="4 4"
                fillOpacity={1}
                fill="url(#investedGrad)"
                name="Ana Para"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Year by Year Table */}
      <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-3">
        <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
          Yıl Yıl Büyüme Tablosu
        </h4>

        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="text-slate-400 border-b border-slate-800">
              <tr>
                <th className="py-2.5 pr-4 font-semibold">Yıl</th>
                <th className="py-2.5 px-4 font-semibold">Yatırılan Ana Para</th>
                <th className="py-2.5 px-4 font-semibold">Bileşik Kar</th>
                <th className="py-2.5 pl-4 text-right font-semibold">Toplam Büyüklük</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 font-mono">
              {yearData.map((row) => (
                <tr key={row.year} className="hover:bg-slate-800/30 transition">
                  <td className="py-2.5 pr-4 font-sans font-bold text-white">{row.year}. Yıl</td>
                  <td className="py-2.5 px-4 text-slate-400">{AppFormatters.currency(row.totalInvested)}</td>
                  <td className="py-2.5 px-4 text-emerald-400 font-bold">
                    +{AppFormatters.currency(row.interestEarned)}
                  </td>
                  <td className="py-2.5 pl-4 text-right font-extrabold text-cyan-400">
                    {AppFormatters.currency(row.totalValue)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
