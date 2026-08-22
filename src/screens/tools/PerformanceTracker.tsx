import React, { useState, useEffect } from 'react';
import { Plus, Trash2, TrendingUp, Target, RefreshCw, BarChart2 } from 'lucide-react';
import { StorageService } from '../../services/storage';
import { MarketDataService } from '../../services/marketData';
import { PerformanceRecord } from '../../types';
import { AppFormatters } from '../../utils/formatters';

interface TableRowData {
  record: PerformanceRecord;
  actualGrowth: number | null;
  diff: number | null;
}

export const PerformanceTracker: React.FC = () => {
  const [targetGrowth, setTargetGrowth] = useState<string>('');
  const [records, setRecords] = useState<PerformanceRecord[]>([]);
  const [ready, setReady] = useState<boolean>(false);
  const [loadingAdd, setLoadingAdd] = useState<boolean>(false);

  const loadData = () => {
    const tg = StorageService.getTargetGrowth();
    const recs = StorageService.getPerformanceRecords();
    setTargetGrowth(tg);
    setRecords(recs);
    setReady(true);
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleTargetGrowthChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setTargetGrowth(val);
    StorageService.saveTargetGrowth(val);
  };

  // Add new snapshot record based on current portfolio value (or manual if zero)
  const handleAddRecord = () => {
    setLoadingAdd(true);
    try {
      const fundHoldings = MarketDataService.calculateFundHoldings();
      const stockHoldings = MarketDataService.calculateStockHoldings();
      
      const fundTotal = fundHoldings.reduce((sum: number, item) => sum + item.currentValue, 0);
      const stockTotal = stockHoldings.reduce((sum: number, item) => sum + item.currentValue, 0);
      const totalPortfolioValue = fundTotal + stockTotal;

      const now = new Date();
      const dateStr = now.toISOString();

      StorageService.addPerformanceRecord(dateStr, totalPortfolioValue);
      setRecords(StorageService.getPerformanceRecords());
    } catch (e) {
      console.error('Error adding record:', e);
    } finally {
      setLoadingAdd(false);
    }
  };

  const handleDeleteLastRecord = () => {
    if (records.length === 0) return;
    if (window.confirm('En son performans kaydı silinecek.\n\nBu işlem geri alınamaz.\n\nDevam etmek istiyor musunuz?')) {
      StorageService.deleteLastPerformanceRecord();
      setRecords(StorageService.getPerformanceRecords());
    }
  };

  const parsedTargetGrowth = parseFloat(targetGrowth.trim().replace(',', '.')) || 0.0;

  // Build table rows
  const rows: TableRowData[] = [];
  for (let i = 0; i < records.length; i++) {
    if (i === 0) {
      rows.push({
        record: records[i],
        actualGrowth: null,
        diff: null,
      });
      continue;
    }

    const previous = records[i - 1].portfolioValue;
    const current = records[i].portfolioValue;
    const actualGrowth = previous === 0 ? 0 : ((current - previous) / previous) * 100;
    const diff = actualGrowth - parsedTargetGrowth;

    rows.push({
      record: records[i],
      actualGrowth,
      diff,
    });
  }

  // Calculate statistics
  const comparableRows = rows.filter((r) => r.actualGrowth !== null);
  const aboveCount = comparableRows.filter((r) => (r.diff ?? 0) > 0).length;
  const belowCount = comparableRows.filter((r) => (r.diff ?? 0) < 0).length;
  const averageGrowth = comparableRows.length === 0
    ? 0.0
    : comparableRows.reduce((sum, r) => sum + (r.actualGrowth ?? 0), 0) / comparableRows.length;
  
  const targetCompound = comparableRows.length === 0
    ? 0.0
    : (Math.pow(1 + parsedTargetGrowth / 100, comparableRows.length) - 1) * 100;

  const realizedCompound = records.length < 2 || records[0].portfolioValue === 0
    ? 0.0
    : ((records[records.length - 1].portfolioValue / records[0].portfolioValue) - 1) * 100;

  const formatDisplayDate = (dStr: string) => {
    try {
      const d = new Date(dStr);
      if (isNaN(d.getTime())) return dStr;
      const day = String(d.getDate()).padStart(2, '0');
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const year = d.getFullYear();
      return `${day}.${month}.${year}`;
    } catch {
      return dStr;
    }
  };

  if (!ready) {
    return (
      <div className="p-8 text-center text-slate-400">
        <RefreshCw className="w-6 h-6 animate-spin mx-auto text-cyan-400 mb-2" />
        Yükleniyor...
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Top Input & Action Bar */}
      <div className="p-5 rounded-2xl bg-[#1A1D24] border border-slate-800 space-y-4">
        <div>
          <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
            <Target className="w-4 h-4 text-cyan-400" />
            Hedef Büyüme %
          </label>
          <input
            type="text"
            value={targetGrowth}
            onChange={handleTargetGrowthChange}
            placeholder="örn. 5"
            className="w-full px-4 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500 transition"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={handleAddRecord}
            disabled={loadingAdd}
            className="flex-1 min-w-[140px] px-4 py-2.5 bg-cyan-500 hover:bg-cyan-400 disabled:opacity-50 text-slate-950 font-bold text-xs rounded-xl transition flex items-center justify-center gap-1.5 shadow-md shadow-cyan-500/20"
          >
            <Plus className="w-4 h-4" />
            ➕ Yeni Kayıt
          </button>

          <button
            onClick={handleDeleteLastRecord}
            disabled={records.length === 0}
            className="flex-1 min-w-[140px] px-4 py-2.5 bg-transparent border border-red-500/40 hover:bg-red-500/10 text-red-400 disabled:opacity-40 disabled:border-slate-800 disabled:text-slate-600 font-bold text-xs rounded-xl transition flex items-center justify-center gap-1.5"
          >
            <Trash2 className="w-4 h-4" />
            🗑 Son Kaydı Sil
          </button>
        </div>
      </div>

      {/* Performance Data Table */}
      <div className="rounded-2xl bg-[#1A1D24] border border-slate-800 overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-800 bg-[#13161C] text-slate-400 font-semibold uppercase tracking-wider">
                <th className="py-3 px-4">Tarih</th>
                <th className="py-3 px-4 text-right">Portföy</th>
                <th className="py-3 px-4 text-right">Gerçek</th>
                <th className="py-3 px-4 text-right">Hedef</th>
                <th className="py-3 px-4 text-right">Fark</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 font-mono">
              {rows.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-slate-500 font-sans">
                    Henüz performans kaydı bulunmuyor. "➕ Yeni Kayıt" ile ekleyebilirsiniz.
                  </td>
                </tr>
              ) : (
                rows.map((row, idx) => {
                  const diffColor =
                    row.diff === null
                      ? 'text-slate-400'
                      : row.diff >= 0
                      ? 'text-emerald-400'
                      : 'text-red-400';

                  return (
                    <tr key={idx} className="hover:bg-slate-800/30 transition">
                      <td className="py-3 px-4 text-slate-300 font-sans">
                        {formatDisplayDate(row.record.date)}
                      </td>
                      <td className="py-3 px-4 text-right font-bold text-white">
                        {AppFormatters.currency(row.record.portfolioValue)}
                      </td>
                      <td className="py-3 px-4 text-right">
                        {row.actualGrowth === null ? (
                          <span className="text-slate-500 font-sans">-</span>
                        ) : (
                          <span
                            className={
                              row.actualGrowth >= 0 ? 'text-emerald-400' : 'text-red-400'
                            }
                          >
                            %{row.actualGrowth.toFixed(2)}
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-right text-slate-300">
                        %{parsedTargetGrowth.toFixed(2)}
                      </td>
                      <td className={`py-3 px-4 text-right font-bold ${diffColor}`}>
                        {row.diff === null ? (
                          <span className="text-slate-500 font-sans">-</span>
                        ) : (
                          <span>
                            {row.diff >= 0 ? '+' : ''}
                            %{row.diff.toFixed(2)}
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* General Statistics */}
      <div className="p-5 rounded-2xl bg-[#1A1D24] border border-slate-800 space-y-3">
        <h4 className="text-sm font-bold text-white flex items-center gap-2 mb-3">
          <BarChart2 className="w-4 h-4 text-cyan-400" />
          Genel İstatistikler
        </h4>

        <div className="space-y-2.5 text-xs">
          <div className="flex justify-between items-center py-1 border-b border-slate-800/60">
            <span className="text-slate-400">Kayıt Sayısı</span>
            <span className="font-bold text-white font-mono">{records.length}</span>
          </div>

          <div className="flex justify-between items-center py-1 border-b border-slate-800/60">
            <span className="text-slate-400">Hedef Üstü Kayıt</span>
            <span className="font-bold text-emerald-400 font-mono">{aboveCount}</span>
          </div>

          <div className="flex justify-between items-center py-1 border-b border-slate-800/60">
            <span className="text-slate-400">Hedef Altı Kayıt</span>
            <span className="font-bold text-red-400 font-mono">{belowCount}</span>
          </div>

          <div className="flex justify-between items-center py-1 border-b border-slate-800/60">
            <span className="text-slate-400">Ortalama Büyüme</span>
            <span
              className={`font-bold font-mono ${
                averageGrowth >= 0 ? 'text-emerald-400' : 'text-red-400'
              }`}
            >
              {averageGrowth >= 0 ? '+' : ''}%{averageGrowth.toFixed(2)}
            </span>
          </div>

          <div className="flex justify-between items-center py-1 border-b border-slate-800/60">
            <span className="text-slate-400">Toplam Hedef Bileşik Getiri</span>
            <span className="font-bold text-cyan-400 font-mono">
              %{targetCompound.toFixed(2)}
            </span>
          </div>

          <div className="flex justify-between items-center py-1">
            <span className="text-slate-400">Toplam Gerçekleşen Bileşik Getiri</span>
            <span
              className={`font-bold font-mono ${
                realizedCompound >= 0 ? 'text-emerald-400' : 'text-red-400'
              }`}
            >
              {realizedCompound >= 0 ? '+' : ''}%{realizedCompound.toFixed(2)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
