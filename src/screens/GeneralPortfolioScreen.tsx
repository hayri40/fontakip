import React, { useState, useEffect } from 'react';
import { MarketDataService } from '../services/marketData';
import { StorageService } from '../services/storage';
import { Holding, StockHolding } from '../types';
import { AppFormatters } from '../utils/formatters';
import { DebtScreen } from './DebtScreen';

interface GeneralPortfolioScreenProps {
  onNavigate: (tab: string) => void;
  onOpenFundTransaction?: (fundCode?: string) => void;
  onOpenStockTransaction?: (stockSymbol?: string) => void;
}

export const GeneralPortfolioScreen: React.FC<GeneralPortfolioScreenProps> = ({
  onNavigate,
}) => {
  const [fundHoldings, setFundHoldings] = useState<Holding[]>([]);
  const [stockHoldings, setStockHoldings] = useState<StockHolding[]>([]);
  const [activeTab, setActiveTab] = useState<'assets' | 'debts'>('assets');

  const loadPortfolio = () => {
    const funds = MarketDataService.calculateFundHoldings();
    const stocks = MarketDataService.calculateStockHoldings();
    setFundHoldings(funds);
    setStockHoldings(stocks);
  };

  useEffect(() => {
    loadPortfolio();
  }, []);

  const fundValue = fundHoldings.reduce((sum, item) => sum + item.currentValue, 0);
  const fundCost = fundHoldings.reduce((sum, item) => sum + item.costValue, 0);
  const stockValue = stockHoldings.reduce((sum, item) => sum + item.currentValue, 0);
  const stockCost = stockHoldings.reduce((sum, item) => sum + item.costValue, 0);
  const fxValue = 0.0;
  const fxCost = 0.0;

  const totalValue = fundValue + stockValue + fxValue;
  const totalCost = fundCost + stockCost;
  const totalProfitLoss = totalValue - totalCost;
  const totalProfitLossPercent = totalCost === 0 ? 0.0 : (totalProfitLoss / totalCost) * 100;

  const fundProfitLoss = fundValue - fundCost;
  const fundProfitLossPercent = fundCost === 0 ? 0.0 : (fundProfitLoss / fundCost) * 100;

  const stockProfitLoss = stockValue - stockCost;
  const stockProfitLossPercent = stockCost === 0 ? 0.0 : (stockProfitLoss / stockCost) * 100;

  const fundPercent = totalValue === 0 ? 0.0 : (fundValue / totalValue) * 100;
  const stockPercent = totalValue === 0 ? 0.0 : (stockValue / totalValue) * 100;

  const isProfit = totalProfitLoss >= 0;

  return (
    <div className="space-y-4 max-w-2xl mx-auto pb-12">
      {/* Top Tab Bar: Varlıklarım / Borçlarım */}
      <div className="flex border-b border-slate-800 bg-[#161922] rounded-xl p-1">
        <button
          onClick={() => setActiveTab('assets')}
          className={`flex-1 py-2.5 text-sm font-semibold rounded-lg transition-all ${
            activeTab === 'assets'
              ? 'bg-[#1A1D24] text-white shadow-sm'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Varlıklarım
        </button>
        <button
          onClick={() => setActiveTab('debts')}
          className={`flex-1 py-2.5 text-sm font-semibold rounded-lg transition-all ${
            activeTab === 'debts'
              ? 'bg-[#1A1D24] text-white shadow-sm'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          Borçlarım
        </button>
      </div>

      {activeTab === 'assets' ? (
        <div className="space-y-3">
          {/* Hero Card: 🏠 Toplam Portföyüm */}
          <div className="bg-[#1A1D24] border border-slate-800/80 rounded-2xl p-5 shadow-lg">
            <div className="text-slate-400 text-sm font-semibold mb-2">
              🏠 Toplam Portföyüm
            </div>
            <div className="text-3xl sm:text-4xl font-bold text-white font-mono tracking-tight">
              {AppFormatters.currency(totalValue)}
            </div>
            <div className="flex items-center justify-between mt-3 pt-3 border-t border-slate-800/60">
              <div className="text-slate-400 text-sm font-medium">
                Maliyet: {AppFormatters.currency(totalCost)}
              </div>
              <div
                className={`text-base sm:text-lg font-bold font-mono ${
                  isProfit ? 'text-green-500' : 'text-red-500'
                }`}
              >
                {AppFormatters.signedCurrency(totalProfitLoss)} ({AppFormatters.percent(totalProfitLossPercent)})
              </div>
            </div>
          </div>

          {/* Breakdown Card: Dağılım */}
          <div className="bg-[#1A1D24] border border-slate-800/80 rounded-2xl p-5 shadow-lg space-y-3">
            <div className="text-base font-bold text-white">Dağılım</div>

            {/* Fon Row */}
            <div
              onClick={() => onNavigate('fund')}
              className="bg-green-500/10 hover:bg-green-500/15 border border-green-500/20 rounded-xl p-3.5 flex items-start justify-between cursor-pointer transition"
            >
              <div className="space-y-1">
                <div className="font-semibold text-white text-base flex items-center gap-2">
                  <span>Fon</span>
                  <span className="text-xs bg-green-500/20 text-green-400 px-2 py-0.5 rounded-full font-normal">
                    {fundHoldings.length} fon
                  </span>
                </div>
                <div className="text-green-400 font-semibold text-sm">
                  Güncel: {AppFormatters.currency(fundValue)}
                </div>
                <div className="text-slate-300 text-xs">
                  Maliyet: {AppFormatters.currency(fundCost)}
                </div>
              </div>
              <div className="text-right space-y-1">
                <div
                  className={`text-sm font-bold font-mono ${
                    fundProfitLoss >= 0 ? 'text-green-400' : 'text-red-400'
                  }`}
                >
                  K/Z: {AppFormatters.signedCurrency(fundProfitLoss)} ({AppFormatters.percent(fundProfitLossPercent)})
                </div>
                <div className="text-slate-400 text-xs font-semibold">
                  Pay {AppFormatters.percent(fundPercent)}
                </div>
              </div>
            </div>

            {/* Hisse Row */}
            <div
              onClick={() => onNavigate('stock')}
              className="bg-blue-500/10 hover:bg-blue-500/15 border border-blue-500/20 rounded-xl p-3.5 flex items-start justify-between cursor-pointer transition"
            >
              <div className="space-y-1">
                <div className="font-semibold text-white text-base flex items-center gap-2">
                  <span>Hisse</span>
                  <span className="text-xs bg-blue-500/20 text-blue-400 px-2 py-0.5 rounded-full font-normal">
                    {stockHoldings.length} hisse
                  </span>
                </div>
                <div className="text-blue-400 font-semibold text-sm">
                  Güncel: {AppFormatters.currency(stockValue)}
                </div>
                <div className="text-slate-300 text-xs">
                  Maliyet: {AppFormatters.currency(stockCost)}
                </div>
              </div>
              <div className="text-right space-y-1">
                <div
                  className={`text-sm font-bold font-mono ${
                    stockProfitLoss >= 0 ? 'text-green-400' : 'text-red-400'
                  }`}
                >
                  K/Z: {AppFormatters.signedCurrency(stockProfitLoss)} ({AppFormatters.percent(stockProfitLossPercent)})
                </div>
                <div className="text-slate-400 text-xs font-semibold">
                  Pay {AppFormatters.percent(stockPercent)}
                </div>
              </div>
            </div>

            {/* FX Row */}
            <div
              onClick={() => onNavigate('fx')}
              className="bg-orange-500/10 hover:bg-orange-500/15 border border-orange-500/20 rounded-xl p-3.5 flex items-start justify-between cursor-pointer transition"
            >
              <div className="space-y-1">
                <div className="font-semibold text-white text-base">FX</div>
                <div className="text-orange-400 font-semibold text-sm">
                  Güncel: {AppFormatters.currency(fxValue)}
                </div>
                <div className="text-slate-300 text-xs">
                  Maliyet: {AppFormatters.currency(fxCost)}
                </div>
              </div>
              <div className="text-right space-y-1">
                <div className="text-sm font-bold text-slate-400 font-mono">
                  K/Z: 0,00 ₺ (%0,00)
                </div>
                <div className="text-slate-400 text-xs font-semibold">
                  Pay %0,00
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <DebtScreen />
      )}
    </div>
  );
};
