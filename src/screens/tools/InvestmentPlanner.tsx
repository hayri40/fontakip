import React, { useState, useEffect } from 'react';
import { Plus, Trash2, CheckCircle2, AlertCircle, PieChart, Layers, DollarSign } from 'lucide-react';
import { AppFormatters } from '../../utils/formatters';

interface FundRow {
  id: string;
  code: string;
  percent: string;
}

export const InvestmentPlanner: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'general' | 'fund'>('general');

  // General tab states
  const [generalBudget, setGeneralBudget] = useState('10000');
  const [generalFundPercent, setGeneralFundPercent] = useState('50');
  const [generalStockPercent, setGeneralStockPercent] = useState('35');
  const [generalFxPercent, setGeneralFxPercent] = useState('15');

  // Fund tab states
  const [fundBudget, setFundBudget] = useState('5000');
  const [fundRows, setFundRows] = useState<FundRow[]>([]);

  // Load from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem('fontakip_planner_prefs');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.generalBudget) setGeneralBudget(parsed.generalBudget);
        if (parsed.generalFundPercent) setGeneralFundPercent(parsed.generalFundPercent);
        if (parsed.generalStockPercent) setGeneralStockPercent(parsed.generalStockPercent);
        if (parsed.generalFxPercent) setGeneralFxPercent(parsed.generalFxPercent);
        if (parsed.fundBudget) setFundBudget(parsed.fundBudget);
        if (parsed.fundRows) setFundRows(parsed.fundRows);
      }
    } catch {}
  }, []);

  // Save to localStorage
  const saveState = (overrides?: any) => {
    const payload = {
      generalBudget,
      generalFundPercent,
      generalStockPercent,
      generalFxPercent,
      fundBudget,
      fundRows,
      ...overrides,
    };
    localStorage.setItem('fontakip_planner_prefs', JSON.stringify(payload));
  };

  const parseNum = (val: string) => {
    return parseFloat(val.replace(',', '.')) || 0;
  };

  // General calculations
  const gBudget = parseNum(generalBudget);
  const gFund = parseNum(generalFundPercent);
  const gStock = parseNum(generalStockPercent);
  const gFx = parseNum(generalFxPercent);
  const gTotalPercent = gFund + gStock + gFx;
  const isGeneralValid = Math.abs(gTotalPercent - 100) < 0.01;

  const fundAllocAmount = (gBudget * gFund) / 100;
  const stockAllocAmount = (gBudget * gStock) / 100;
  const fxAllocAmount = (gBudget * gFx) / 100;

  // Fund tab calculations
  const fBudget = parseNum(fundBudget);
  const fTotalPercent = fundRows.reduce((sum, r) => sum + parseNum(r.percent), 0);
  const isFundValid = Math.abs(fTotalPercent - 100) < 0.01;

  const addFundRow = () => {
    const next: FundRow[] = [
      ...fundRows,
      { id: Date.now().toString(), code: '', percent: '' },
    ];
    setFundRows(next);
    saveState({ fundRows: next });
  };

  const removeFundRow = (id: string) => {
    const next = fundRows.filter((r) => r.id !== id);
    setFundRows(next);
    saveState({ fundRows: next });
  };

  const updateFundRow = (id: string, field: 'code' | 'percent', val: string) => {
    const next = fundRows.map((r) => (r.id === id ? { ...r, [field]: val } : r));
    setFundRows(next);
    saveState({ fundRows: next });
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
          Genel Portföy Dağılımı
        </button>
        <button
          onClick={() => setActiveTab('fund')}
          className={`px-4 py-2 text-xs sm:text-sm font-semibold rounded-xl transition ${
            activeTab === 'fund'
              ? 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/30'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Fon Özel Dağılımı
        </button>
      </div>

      {activeTab === 'general' ? (
        <div className="space-y-5">
          {/* Inputs Card */}
          <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
            <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
              Aylık Yatırım Bütçesi ve Hedef Yüzdeler
            </h4>

            <div>
              <label className="block text-xs text-slate-400 font-medium mb-1.5">
                Aylık Yatırım Bütçesi (₺)
              </label>
              <input
                type="number"
                value={generalBudget}
                onChange={(e) => {
                  setGeneralBudget(e.target.value);
                  saveState({ generalBudget: e.target.value });
                }}
                className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
              />
            </div>

            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="block text-xs text-cyan-400 font-semibold mb-1">Fon %</label>
                <input
                  type="number"
                  value={generalFundPercent}
                  onChange={(e) => {
                    setGeneralFundPercent(e.target.value);
                    saveState({ generalFundPercent: e.target.value });
                  }}
                  className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="block text-xs text-emerald-400 font-semibold mb-1">Hisse %</label>
                <input
                  type="number"
                  value={generalStockPercent}
                  onChange={(e) => {
                    setGeneralStockPercent(e.target.value);
                    saveState({ generalStockPercent: e.target.value });
                  }}
                  className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="block text-xs text-amber-400 font-semibold mb-1">FX / Emtia %</label>
                <input
                  type="number"
                  value={generalFxPercent}
                  onChange={(e) => {
                    setGeneralFxPercent(e.target.value);
                    saveState({ generalFxPercent: e.target.value });
                  }}
                  className="w-full px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-cyan-500"
                />
              </div>
            </div>

            {/* Validation */}
            <div className="flex items-center gap-2 text-xs">
              {isGeneralValid ? (
                <span className="text-emerald-400 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-4 h-4" /> Toplam: %{gTotalPercent.toFixed(0)} (Hedef tamam)
                </span>
              ) : (
                <span className="text-red-400 font-semibold flex items-center gap-1">
                  <AlertCircle className="w-4 h-4" /> Toplam: %{gTotalPercent.toFixed(0)} (Yüzdeler toplamı 100 olmalı)
                </span>
              )}
            </div>
          </div>

          {/* Results Summary */}
          <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 space-y-4">
            <h4 className="text-xs font-bold text-cyan-400 uppercase tracking-wider">
              Aylık Dağıtılacak Tutarlar
            </h4>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-3.5 rounded-xl bg-[#11141E] border border-cyan-500/20">
                <div className="text-xs text-cyan-400 font-medium">Fonlara Ayrılan</div>
                <div className="text-lg font-bold text-white font-mono mt-1">
                  {AppFormatters.currency(fundAllocAmount)}
                </div>
                <div className="text-[11px] text-slate-400">%{gFund} pay</div>
              </div>

              <div className="p-3.5 rounded-xl bg-[#11141E] border border-emerald-500/20">
                <div className="text-xs text-emerald-400 font-medium">Hisselere Ayrılan</div>
                <div className="text-lg font-bold text-white font-mono mt-1">
                  {AppFormatters.currency(stockAllocAmount)}
                </div>
                <div className="text-[11px] text-slate-400">%{gStock} pay</div>
              </div>

              <div className="p-3.5 rounded-xl bg-[#11141E] border border-amber-500/20">
                <div className="text-xs text-amber-400 font-medium">FX / Emtia Ayrılan</div>
                <div className="text-lg font-bold text-white font-mono mt-1">
                  {AppFormatters.currency(fxAllocAmount)}
                </div>
                <div className="text-[11px] text-slate-400">%{gFx} pay</div>
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
                Fon Bazlı Aylık Bütçe Dağılımı
              </h4>
              <button
                onClick={addFundRow}
                className="px-3 py-1 bg-cyan-500/10 hover:bg-cyan-500/20 text-cyan-400 text-xs font-semibold rounded-lg border border-cyan-500/30 flex items-center gap-1 transition"
              >
                <Plus className="w-3.5 h-3.5" /> Fon Satırı Ekle
              </button>
            </div>

            <div>
              <label className="block text-xs text-slate-400 font-medium mb-1.5">
                Fonlara Ayrılan Aylık Bütçe (₺)
              </label>
              <input
                type="number"
                value={fundBudget}
                onChange={(e) => {
                  setFundBudget(e.target.value);
                  saveState({ fundBudget: e.target.value });
                }}
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
                    placeholder="Fon Kodu (örn. KLU)"
                    className="flex-1 px-3.5 py-2 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm uppercase focus:outline-none focus:border-cyan-500"
                  />
                  <div className="w-28 relative">
                    <input
                      type="number"
                      value={row.percent}
                      onChange={(e) => updateFundRow(row.id, 'percent', e.target.value)}
                      placeholder="%"
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

            {/* Total Check */}
            <div className="flex items-center gap-2 text-xs pt-1">
              {isFundValid ? (
                <span className="text-emerald-400 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-4 h-4" /> Toplam Yüzde: %{fTotalPercent.toFixed(0)}
                </span>
              ) : (
                <span className="text-red-400 font-semibold flex items-center gap-1">
                  <AlertCircle className="w-4 h-4" /> Toplam Yüzde: %{fTotalPercent.toFixed(0)} (100 olmalı)
                </span>
              )}
            </div>
          </div>

          {/* Fund Allocation Results */}
          {isFundValid && (
            <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 space-y-3">
              <h4 className="text-xs font-bold text-cyan-400 uppercase tracking-wider">
                Alınacak Fon Tutarları
              </h4>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {fundRows.map((row) => {
                  const percent = parseNum(row.percent);
                  const amount = (fBudget * percent) / 100;
                  return (
                    <div key={row.id} className="p-3.5 rounded-xl bg-[#11141E] border border-slate-800">
                      <div className="flex justify-between items-center text-xs">
                        <span className="font-bold text-white font-mono">{row.code || 'Bilinmeyen Fon'}</span>
                        <span className="text-cyan-400 font-semibold">%{percent}</span>
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
