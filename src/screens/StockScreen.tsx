import React, { useState, useEffect } from 'react';
import {
  Search,
  PlusCircle,
  Star,
  TrendingUp,
  TrendingDown,
  Trash2,
  Building2,
  Layers,
  ArrowDownRight,
  ArrowUpRight,
} from 'lucide-react';
import { Stock, StockHolding, StockTransaction } from '../types';
import { MarketDataService, BIST_STOCKS } from '../services/marketData';
import { StorageService } from '../services/storage';
import { StockDetailModal } from '../components/StockDetailModal';
import { AppFormatters } from '../utils/formatters';

interface StockScreenProps {
  onOpenTransaction: (stockSymbol?: string, currentPrice?: number) => void;
}

export const StockScreen: React.FC<StockScreenProps> = ({ onOpenTransaction }) => {
  const [activeTab, setActiveTab] = useState<'portfolio' | 'market' | 'transactions' | 'favorites'>('portfolio');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStock, setSelectedStock] = useState<Stock | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [holdings, setHoldings] = useState<StockHolding[]>([]);
  const [transactions, setTransactions] = useState<StockTransaction[]>([]);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [stocks, setStocks] = useState<Stock[]>(BIST_STOCKS);

  const loadData = () => {
    setHoldings(MarketDataService.calculateStockHoldings());
    setTransactions(StorageService.getStockTransactions());
    setFavorites(StorageService.getStockFavorites());
    setStocks(MarketDataService.searchStocks(''));
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSearch = (q: string) => {
    setSearchQuery(q);
    setStocks(MarketDataService.searchStocks(q));
  };

  const handleSelectStockSymbol = (symbol: string) => {
    const stock = MarketDataService.getStockDetail(symbol);
    setSelectedStock(stock);
    setIsModalOpen(true);
    StorageService.setLastStockSymbol(symbol);
  };

  const handleDeleteTransaction = (id: string) => {
    if (window.confirm('Bu hisse işlemini silmek istediğinize emin misiniz?')) {
      StorageService.deleteStockTransaction(id);
      loadData();
    }
  };

  const toggleFav = (symbol: string, e: React.MouseEvent) => {
    e.stopPropagation();
    StorageService.toggleStockFavorite(symbol);
    setFavorites(StorageService.getStockFavorites());
  };

  const totalStockValue = holdings.reduce((sum, h) => sum + h.currentValue, 0);
  const totalStockCost = holdings.reduce((sum, h) => sum + h.costValue, 0);
  const totalProfitLoss = totalStockValue - totalStockCost;
  const totalProfitLossPercent = totalStockCost > 0 ? (totalProfitLoss / totalStockCost) * 100 : 0;
  const totalDailyChange = holdings.reduce((sum, h) => sum + h.dailyChangeValue, 0);

  return (
    <div className="space-y-5 pb-24 animate-in fade-in duration-200">
      {/* Sub Tabs */}
      <div className="flex items-center justify-between border-b border-slate-800 pb-2">
        <div className="flex gap-1.5 overflow-x-auto">
          {[
            { id: 'portfolio', label: 'Portföyüm' },
            { id: 'market', label: 'BIST Piyasa' },
            { id: 'transactions', label: 'İşlemler' },
            { id: 'favorites', label: 'Favoriler' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-3.5 py-1.5 text-xs sm:text-sm font-semibold rounded-xl transition whitespace-nowrap ${
                activeTab === tab.id
                  ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <button
          onClick={() => onOpenTransaction()}
          className="px-3 py-1.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold text-xs transition flex items-center gap-1.5 shadow-md shadow-emerald-500/20 whitespace-nowrap"
        >
          <PlusCircle className="w-3.5 h-3.5" />
          Hisse Ekle
        </button>
      </div>

      {/* PORTFOLIO TAB */}
      {activeTab === 'portfolio' && (
        <div className="space-y-4">
          {/* Summary Card */}
          <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-emerald-400 uppercase tracking-wider flex items-center gap-1.5">
                <TrendingUp className="w-4 h-4" />
                Toplam Hisse Portföy Değeri
              </span>
              <span className="text-xs text-slate-400 font-medium">{holdings.length} Hisse Pozisyonu</span>
            </div>

            <div className="text-3xl font-extrabold text-white font-mono">
              {AppFormatters.currency(totalStockValue)}
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-3 border-t border-slate-800">
              <div>
                <div className="text-[11px] text-slate-400">Toplam Kar/Zarar</div>
                <div
                  className={`text-sm font-bold font-mono ${
                    totalProfitLoss >= 0 ? 'text-emerald-400' : 'text-red-400'
                  }`}
                >
                  {totalProfitLoss >= 0 ? '+' : ''}
                  {AppFormatters.signedCurrency(totalProfitLoss)} ({AppFormatters.signedPercent(totalProfitLossPercent)})
                </div>
              </div>

              <div>
                <div className="text-[11px] text-slate-400">Toplam Maliyet</div>
                <div className="text-sm font-bold text-slate-300 font-mono">
                  {AppFormatters.currency(totalStockCost)}
                </div>
              </div>

              <div className="col-span-2 sm:col-span-1">
                <div className="text-[11px] text-slate-400">Günlük Değişim</div>
                <div
                  className={`text-sm font-bold font-mono ${
                    totalDailyChange >= 0 ? 'text-emerald-400' : 'text-red-400'
                  }`}
                >
                  {totalDailyChange >= 0 ? '+' : ''}
                  {AppFormatters.signedCurrency(totalDailyChange)}
                </div>
              </div>
            </div>
          </div>

          {/* Holdings List */}
          <div className="space-y-2.5">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider px-1">
              Hisse Pozisyonlarım
            </h3>

            {holdings.length === 0 ? (
              <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400 space-y-3">
                <Building2 className="w-10 h-10 mx-auto text-slate-600" />
                <p className="text-sm">Henüz portföyünüzde BIST hissesi bulunmuyor.</p>
                <button
                  onClick={() => onOpenTransaction()}
                  className="px-4 py-2 bg-emerald-500 text-slate-950 font-bold rounded-xl text-xs"
                >
                  Hisse Alışı Ekle
                </button>
              </div>
            ) : (
              holdings.map((h) => (
                <div
                  key={h.stockSymbol}
                  onClick={() => handleSelectStockSymbol(h.stockSymbol)}
                  className="p-4 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 hover:border-emerald-500/40 transition cursor-pointer flex flex-col sm:flex-row sm:items-center justify-between gap-3 group"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-11 h-11 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 font-extrabold text-sm">
                      {h.stockSymbol}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white text-base group-hover:text-emerald-400 transition">
                          {h.stockSymbol}
                        </span>
                        <span className="text-[11px] px-2 py-0.5 rounded bg-slate-800 text-slate-300">
                          {AppFormatters.percent(h.portfolioSharePercent)} pay
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 line-clamp-1 max-w-xs sm:max-w-sm mt-0.5">
                        {h.name}
                      </div>
                      <div className="text-[11px] text-slate-500 mt-1">
                        {AppFormatters.number(h.quantity, 0)} lot • Fiyat: {AppFormatters.currency(h.currentPrice)} • Ort: {AppFormatters.currency(h.averageCost)}
                      </div>
                    </div>
                  </div>

                  <div className="text-left sm:text-right border-t sm:border-t-0 pt-2 sm:pt-0 border-slate-800 flex sm:flex-col justify-between sm:justify-center items-baseline sm:items-end">
                    <div className="text-base font-extrabold text-white font-mono">
                      {AppFormatters.currency(h.currentValue)}
                    </div>
                    <div
                      className={`text-xs font-semibold flex items-center gap-1 font-mono ${
                        h.profitLoss >= 0 ? 'text-emerald-400' : 'text-red-400'
                      }`}
                    >
                      {h.profitLoss >= 0 ? <TrendingUp className="w-3.5 h-3.5" /> : <TrendingDown className="w-3.5 h-3.5" />}
                      {AppFormatters.signedCurrency(h.profitLoss)} ({AppFormatters.signedPercent(h.profitLossPercent)})
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {/* MARKET TAB */}
      {activeTab === 'market' && (
        <div className="space-y-4">
          <div className="relative">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => handleSearch(e.target.value)}
              placeholder="Hisse Sembolü (örn. THYAO, ASELS) veya Şirket Adı ile ara..."
              className="w-full pl-11 pr-4 py-3 bg-[#141824] border border-slate-700/80 rounded-2xl text-white placeholder-slate-500 text-sm focus:outline-none focus:border-emerald-500 shadow-inner"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {stocks.map((s) => {
              const isFav = favorites.includes(s.symbol);
              const isPos = (s.changePercent ?? 0) >= 0;
              return (
                <div
                  key={s.symbol}
                  onClick={() => handleSelectStockSymbol(s.symbol)}
                  className="p-4 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 hover:border-emerald-500/40 transition cursor-pointer flex items-center justify-between gap-3 group"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 font-bold text-sm">
                      {s.symbol}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white text-sm group-hover:text-emerald-400 transition">
                          {s.symbol}
                        </span>
                        <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-800 text-slate-400">
                          {s.sector}
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 line-clamp-1 max-w-[150px] sm:max-w-xs mt-0.5">
                        {s.name}
                      </div>
                      <div className="text-xs font-mono text-slate-200 mt-1 font-bold">
                        {AppFormatters.currency(s.currentPrice)}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div
                      className={`text-xs font-bold px-2 py-1 rounded-lg ${
                        isPos ? 'bg-emerald-500/15 text-emerald-400' : 'bg-red-500/15 text-red-400'
                      }`}
                    >
                      {AppFormatters.signedPercent(s.changePercent)}
                    </div>
                    <button
                      onClick={(e) => toggleFav(s.symbol, e)}
                      className={`p-1.5 rounded-lg border transition ${
                        isFav
                          ? 'bg-amber-500/20 border-amber-500/40 text-amber-400'
                          : 'bg-slate-800/40 border-slate-700/60 text-slate-500 hover:text-slate-300'
                      }`}
                    >
                      <Star className={`w-4 h-4 ${isFav ? 'fill-amber-400' : ''}`} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* TRANSACTIONS TAB */}
      {activeTab === 'transactions' && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Hisse Alım / Satım Geçmişi ({transactions.length})
            </span>
          </div>

          {transactions.length === 0 ? (
            <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400">
              Henüz hisse işlemi kaydedilmemiş.
            </div>
          ) : (
            <div className="space-y-2">
              {transactions.map((tx) => (
                <div
                  key={tx.id}
                  className="p-3.5 rounded-xl bg-[#141824] border border-slate-800 flex items-center justify-between gap-3"
                >
                  <div className="flex items-center gap-3">
                    <div
                      className={`p-2 rounded-xl border ${
                        tx.type === 'BUY'
                          ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400'
                          : 'bg-red-500/10 border-red-500/20 text-red-400'
                      }`}
                    >
                      {tx.type === 'BUY' ? <ArrowDownRight className="w-4 h-4" /> : <ArrowUpRight className="w-4 h-4" />}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white text-sm font-mono">{tx.stockSymbol}</span>
                        <span
                          className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                            tx.type === 'BUY' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'
                          }`}
                        >
                          {tx.type === 'BUY' ? 'ALIŞ' : 'SATIŞ'}
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 mt-0.5">
                        {AppFormatters.number(tx.quantity, 0)} lot • {AppFormatters.currency(tx.unitPrice)}
                      </div>
                      <div className="text-[10px] text-slate-500">{AppFormatters.date(tx.date)}</div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="text-right">
                      <div className="text-sm font-bold text-white font-mono">
                        {AppFormatters.currency(tx.quantity * tx.unitPrice)}
                      </div>
                    </div>
                    <button
                      onClick={() => handleDeleteTransaction(tx.id)}
                      className="p-1.5 text-slate-500 hover:text-red-400 transition"
                      title="İşlemi Sil"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* FAVORITES TAB */}
      {activeTab === 'favorites' && (
        <div className="space-y-3">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Favori Hisselerim ({favorites.length})
          </span>

          {favorites.length === 0 ? (
            <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400">
              Henüz favori hisse eklenmemiş. BIST Piyasa sekmesinden yıldız ikonuna tıklayarak favorilere ekleyebilirsiniz.
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {favorites.map((sym) => {
                const stock = MarketDataService.getStockDetail(sym);
                return (
                  <div
                    key={sym}
                    onClick={() => handleSelectStockSymbol(sym)}
                    className="p-4 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 hover:border-emerald-500/40 transition cursor-pointer flex items-center justify-between gap-3 group"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 font-bold text-sm">
                        {sym}
                      </div>
                      <div>
                        <div className="font-bold text-white text-sm group-hover:text-emerald-400 transition">
                          {sym}
                        </div>
                        <div className="text-xs text-slate-400 line-clamp-1 max-w-[160px]">
                          {stock.name}
                        </div>
                        <div className="text-xs font-mono text-slate-300 mt-1 font-semibold">
                          {AppFormatters.currency(stock.currentPrice)}
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={(e) => toggleFav(sym, e)}
                      className="p-2 rounded-lg bg-amber-500/20 border border-amber-500/40 text-amber-400"
                    >
                      <Star className="w-4 h-4 fill-amber-400" />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Stock Detail Modal */}
      <StockDetailModal
        stock={selectedStock}
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onOpenTransaction={(sym, price) => {
          setIsModalOpen(false);
          onOpenTransaction(sym, price);
        }}
      />
    </div>
  );
};
