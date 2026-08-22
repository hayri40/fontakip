import React, { useState, useEffect } from 'react';
import { Plus, Trash2, CheckCircle2, AlertCircle, RefreshCw, Layers, TrendingUp } from 'lucide-react';
import { MarketDataService } from '../../services/marketData';
import { Holding, StockHolding } from '../../types';
import { AppFormatters } from '../../utils/formatters';

interface FundSimRow {
  id: string;
  code: string;
  percent: string;
}

export const PortfolioBalancer: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'general' | 'fund'>('general');
  const [fundHoldings, setFundHoldings] = useState<Holding[]>([]);
  const [stockHoldings, setStockHoldings] = useState<StockHolding[]>([]);

  // General balancer inputs
  const [generalBudget, setGeneralBudget] = useState('10000');
  const [targetFundPercent, setTargetFundPercent] = useState('50');
  const [targetStockPercent, setTargetStockPercent] = useState('35');
  const [targetFxPercent, setTargetFxPercent] = useState('15');

  // Fund balancer inputs
  const [fundBudget, setFundBudget] = useState('5000');
  const [fundRows, setFundRows] = useState<FundSimRow[]>([]);

  useEffect(() => {
    const funds = MarketDataService.calculateFundHoldings();
    const stocks = MarketDataService.calculateStockHoldings();
    setFundHoldings(funds);
    setStockHoldings(stocks);

    // Initial fund rows from current holdings if present
    if (funds.length > 0) {
      const totalF = funds.reduce((sum, f) => sum + f.currentValue, 0);
      setFundRows(
        funds.map((f, i) => ({
          id: `fund-row-${i}`,
          code: f.fundCode,
          percent: totalF > 0 ? ((f.currentValue / totalF) * 100).toFixed(1) : '',
        }))
      );
    } else {
      setFundRows([]);
    }
  }, []);

  const parseNum = (val: string) => {
    return parseFloat(val.replace(',', '.')) || 0;
  };

  // General Calculations
  const currentFundValue = fundHoldings.reduce((sum, f) => sum + f.currentValue, 0);
  const currentStockValue = stockHoldings.reduce((sum, s) => sum + s.currentValue, 0);
  const currentFxValue = 0;
  const currentTotal = currentFundValue + currentStockValue + currentFxValue;

  const currentFundPercent = currentTotal > 0 ? (currentFundValue / currentTotal) * 100 : 0;
  const currentStockPercent = currentTotal > 0 ? (currentStockValue / currentTotal) * 100 : 0;
  const currentFxPercent = currentTotal > 0 ? (currentFxValue / currentTotal) * 100 : 0;

  const gBudget = parseNum(generalBudget);
  const tFund = parseNum(targetFundPercent);
  const tStock = parseNum(targetStockPercent);
  const tFx = parseNum(targetFxPercent);
  const gTotalTargetPercent = tFund + tStock + tFx;
  const isGeneralValid = Math.abs(gTotalTargetPercent - 100) < 0.01;

  // Deficit Allocation Algorithm
  const allocateByDeficit = (
    budget: number,
    currentValues: Record<string, number>,
    targetPercents: Record<string, number>,
    tot: number
  ) => {
    if (budget <= 0 || Object.keys(targetPercents).length === 0) return {};
    const targetTotal = tot + budget;
    const deficits: Record<string, number> = {};
    let positiveTotal = 0;

    for (const [key, targetP] of Object.entries(targetPercents)) {
      const currentVal = currentValues[key] || 0;
      const desiredVal = (targetTotal * targetP) / 100;
      const deficit = desiredVal - currentVal;
      const positiveDeficit = deficit > 0 ? deficit : 0;
      deficits[key] = positiveDeficit;
      positiveTotal += positiveDeficit;
    }

    if (positiveTotal <= 0) {
      // Fallback proportionally
      const res: Record<string, number> = {};
      for (const [key, targetP] of Object.entries(targetPercents)) {
        res[key] = (budget * targetP) / 100;
      }
      return res;
    }

    const allocations: Record<string, number> = {};
    for (const [key, def] of Object.entries(deficits)) {
      allocations[key] = (budget * def) / positiveTotal;
    }
    return allocations;
  };

  const generalAllocations = allocateByDeficit(
    gBudget,
    { Fon: currentFundValue, Hisse: currentStockValue, FX: currentFxValue },
    { Fon: tFund, Hisse: tStock, FX: tFx },
    currentTotal
  );

  // Fund tab calculations
  const fBudget = parseNum(fundBudget);
  const fTargetTotalPercent = fundRows.reduce((sum, r) => sum + parseNum(r.percent), 0);
  const isFundValid = Math.abs(fTargetTotalPercent - 100) < 0.01;

  const fundCurrentValues: Record<string, number> = {};
  for (const h of fundHoldings) {
    fundCurrentValues[h.fundCode.toUpperCase()] = h.currentValue;
  }
  const fundTargetPercents: Record<string, number> = {};
  for (const r of fundRows) {
    if (r.code.trim()) {
      fundTargetPercents[r.code.trim().toUpperCase()] = parseNum(r.percent);
      if (!fundCurrentValues[r.code.trim().toUpperCase()]) {
        fundCurrentValues[r.code.trim().toUpperCase()] = 0;
      }
    }
  }

  const fundAllocations = allocateByDeficit(
    fBudget,
    fundCurrentValues,
    fundTargetPercents,
    currentFundValue
  );

  const addFundRow = () => {
    setFundRows([...fundRows, { id: Date.now().toString(), code: '', percent: '' }]);
  };

  const removeFundRow = (id: string) => {
    setFundRows(fundRows.filter((r) => r.id !== id));
  };

  const updateFundRow = (id: string, field: 'code' | 'percent', val: string) => {
    setFundRows(fundRows.map((r) => (r.id === id ? { ...r, [field]: val } : r)));
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Sub Tabs */}
      <div className="flex border-b border-slate-800 pb-2 gap-2">
        <button
          onClick={() => setActiveTab('general')}
          className={`px-4 py-2 text-xs sm:text-sm font-semibold rounded-xl transition ${
            activeTab === 'general'
              ? 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/30'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Genel Portföy Dengeleme
        </button>
        <button
          onClick={() => setActiveTab('fund')}
          className={`px-4 py-2 text-xs sm:text-sm font-semibold rounded-xl transition ${
            activeTab === 'fund'
              ? 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/30'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Fon Portföy Dengeleme
        </button>
      </div>

      {activeTab === 'general' ? (
        <div className="space-y-5">
          {/* Current Allocation Card */}
          <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-3">
            <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
              Mevcut Varlık Dağılımı
            </h4>
            <div className="grid grid-cols-3 gap-3">
              <div className="p-3 rounded-xl bg-[#10131B] border border-slate-800">
                <div className="text-xs text-cyan-400 font-semibold">Fon</div>
                <div className="text-sm font-bold text-white mt-0.5">{AppFormatters.currency(currentFundValue)}</div>
                <div className="text-xs text-slate-400">%{currentFundPercent.toFixed(1)}</div>
              </div>
              <div className="p-3 rounded-xl bg-[#10131B] border border-slate-800">
                <div className="text-xs text-emerald-400 font-semibold">Hisse</div>
                <div className="text-sm font-bold text-white mt-0.5">{AppFormatters.currency(currentStockValue)}</div>
                <div className="text-xs text-slate-400">%{currentStockPercent.toFixed(1)}</div>
              </div>
              <div className="p-3 rounded-xl bg-[#10131B] border border-slate-800">
                <div className="text-xs text-amber-400 font-semibold">FX / Emtia</div>
                <div className="text-sm font-bold text-white mt-0.5">{AppFormatters.currency(currentFxValue)}</div>
                <div className="text-xs text-slate-400">%{currentFxPercent.toFixed(1)}</div>
              </div>
            </div>
          </div>

          {/* Target & Budget Inputs */}
          <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
            <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
              Ek Yatırım Bütçesi ve Hedef Yüzdeler
            </h4>

            <div>
              <label className="block text-xs text-slate-400 font-medium mb-1.5">
                Ek Yatırım Bütçesi (₺)
              </label>
              <input
                type="number"
                value={generalBudget}
                onChange={(e) => setGeneralBudget(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
              />
            </div>

            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="block text-xs text-cyan-400 font-semibold mb-1">Hedef Fon %</label>
                <input
                  type="number"
                  value={targetFundPercent}
                  onChange={(e) => setTargetFundPercent(e.target.value)}
                  className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="block text-xs text-emerald-400 font-semibold mb-1">Hedef Hisse %</label>
                <input
                  type="number"
                  value={targetStockPercent}
                  onChange={(e) => setTargetStockPercent(e.target.value)}
                  className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="block text-xs text-amber-400 font-semibold mb-1">Hedef FX %</label>
                <input
                  type="number"
                  value={targetFxPercent}
                  onChange={(e) => setTargetFxPercent(e.target.value)}
                  className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
                />
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs">
              {isGeneralValid ? (
                <span className="text-emerald-400 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-4 h-4" /> Hedef Toplam: %{gTotalTargetPercent.toFixed(0)}
                </span>
              ) : (
                <span className="text-red-400 font-semibold flex items-center gap-1">
                  <AlertCircle className="w-4 h-4" /> Hedef Toplam: %{gTotalTargetPercent.toFixed(0)} (100 olmalı)
                </span>
              )}
            </div>
          </div>

          {/* Dengeleme Sonuçları (Akıllı Eksik Kapatma Algoritması) */}
          <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 space-y-4">
            <h4 className="text-xs font-bold text-cyan-400 uppercase tracking-wider">
              Hedef Dağılıma Ulaşmak İçin Ek Bütçe Dağılımı
            </h4>
            <p className="text-xs text-slate-400">
              Satış yapmadan, yeni nakdi geride kalan varlıklara aktararak hedef oranlara yaklaştırır.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-3.5 rounded-xl bg-[#11141E] border border-cyan-500/20">
                <div className="text-xs text-cyan-400 font-medium">Fonlara Eklenecek</div>
                <div className="text-lg font-bold text-white font-mono mt-1">
                  {AppFormatters.currency(generalAllocations['Fon'] || 0)}
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-[#11141E] border border-emerald-500/20">
                <div className="text-xs text-emerald-400 font-medium">Hisselere Eklenecek</div>
                <div className="text-lg font-bold text-white font-mono mt-1">
                  {AppFormatters.currency(generalAllocations['Hisse'] || 0)}
                </div>
              </div>

              <div className="p-3.5 rounded-xl bg-[#11141E] border border-amber-500/20">
                <div className="text-xs text-amber-400 font-medium">FX / Emtia Eklenecek</div>
                <div className="text-lg font-bold text-white font-mono mt-1">
                  {AppFormatters.currency(generalAllocations['FX'] || 0)}
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        /* Fund Tab */
        <div className="space-y-5">
          <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
            <div className="flex justify-between items-center">
              <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
                Fon Hedef Ağırlıkları & Ek Bütçe
              </h4>
              <button
                onClick={addFundRow}
                className="px-3 py-1 bg-cyan-500/10 hover:bg-cyan-500/20 text-cyan-400 text-xs font-semibold rounded-lg border border-cyan-500/30 flex items-center gap-1 transition"
              >
                <Plus className="w-3.5 h-3.5" /> Fon Ekle
              </button>
            </div>

            <div>
              <label className="block text-xs text-slate-400 font-medium mb-1.5">
                Ek Fon Bütçesi (₺)
              </label>
              <input
                type="number"
                value={fundBudget}
                onChange={(e) => setFundBudget(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
              />
            </div>

            <div className="space-y-2.5">
              {fundRows.map((row) => (
                <div key={row.id} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={row.code}
                    onChange={(e) => updateFundRow(row.id, 'code', e.target.value.toUpperCase())}
                    placeholder="Fon Kodu"
                    className="flex-1 px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm uppercase focus:outline-none focus:border-cyan-500"
                  />
                  <div className="w-28 relative">
                    <input
                      type="number"
                      value={row.percent}
                      onChange={(e) => updateFundRow(row.id, 'percent', e.target.value)}
                      placeholder="Hedef %"
                      className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500 pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs text-slate-400 font-bold">
                      %
                    </span>
                  </div>
                  <button
                    onClick={() => removeFundRow(row.id)}
                    className="p-2 text-slate-500 hover:text-red-400 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>

            <div className="flex items-center gap-2 text-xs pt-1">
              {isFundValid ? (
                <span className="text-emerald-400 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-4 h-4" /> Hedef Toplamı: %{fTargetTotalPercent.toFixed(0)}
                </span>
              ) : (
                <span className="text-red-400 font-semibold flex items-center gap-1">
                  <AlertCircle className="w-4 h-4" /> Hedef Toplamı: %{fTargetTotalPercent.toFixed(0)} (100 olmalı)
                </span>
              )}
            </div>
          </div>

          {/* Results */}
          {isFundValid && (
            <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 space-y-3">
              <h4 className="text-xs font-bold text-cyan-400 uppercase tracking-wider">
                Dengeleme İçin Fon Alım Tutarları
              </h4>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {fundRows
                  .filter((r) => r.code.trim())
                  .map((row) => {
                    const code = row.code.trim().toUpperCase();
                    const amount = fundAllocations[code] || 0;
                    return (
                      <div key={row.id} className="p-3.5 rounded-xl bg-[#11141E] border border-slate-800">
                        <div className="flex justify-between items-center text-xs">
                          <span className="font-bold text-white font-mono">{code}</span>
                          <span className="text-cyan-400 font-semibold">Hedef: %{row.percent}</span>
                        </div>
                        <div className="text-base font-extrabold text-white font-mono mt-1">
                          {AppFormatters.currency(amount)}
                        </div>
                      </div>
                    );
                  })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
