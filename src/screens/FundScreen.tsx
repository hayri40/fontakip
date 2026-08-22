import React, { useState, useEffect } from 'react';
import {
  Search,
  PlusCircle,
  Star,
  Layers,
  TrendingUp,
  TrendingDown,
  Trash2,
  Filter,
  Calendar,
  DollarSign,
  ArrowDownRight,
  ArrowUpRight,
  Shield,
  Activity,
} from 'lucide-react';
import { Fund, Holding, FundTransaction } from '../types';
import { MarketDataService } from '../services/marketData';
import { StorageService } from '../services/storage';
import { FundDetailModal } from '../components/FundDetailModal';
import { AppFormatters } from '../utils/formatters';

interface FundScreenProps {
  onOpenTransaction: (fundCode?: string, currentPrice?: number) => void;
}

export const FundScreen: React.FC<FundScreenProps> = ({ onOpenTransaction }) => {
  const [activeTab, setActiveTab] = useState<'portfolio' | 'search' | 'transactions' | 'favorites'>('portfolio');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('Tümü');
  const [selectedFund, setSelectedFund] = useState<Fund | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [holdings, setHoldings] = useState<Holding[]>([]);
  const [transactions, setTransactions] = useState<FundTransaction[]>([]);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [searchResults, setSearchResults] = useState<{ code: string; name: string; currentPrice: number; return1Y: number; category?: string }[]>([]);

  const loadData = () => {
    setHoldings(MarketDataService.calculateFundHoldings());
    setTransactions(StorageService.getFundTransactions());
    setFavorites(StorageService.getFundFavorites());
    filterResults('', selectedCategory);
  };

  useEffect(() => {
    loadData();
  }, []);

  const filterResults = (query: string, cat: string) => {
    const rawResults = MarketDataService.searchFunds(query);
    if (cat === 'Tümü') {
      setSearchResults(rawResults);
    } else {
      const filtered = rawResults.filter((f) => {
        const c = (f.category || '').toLowerCase();
        const n = f.name.toLowerCase();
        if (cat === 'Katılım') return c.includes('katılım') || n.includes('katılım');
        if (cat === 'Hisse') return c.includes('hisse') || n.includes('hisse');
        if (cat === 'Para Piyasası') return c.includes('para') || n.includes('para');
        if (cat === 'Altın & Emtia') return c.includes('altın') || c.includes('maden') || c.includes('gümüş') || n.includes('altın');
        if (cat === 'Yabancı & Teknoloji') return c.includes('yabancı') || c.includes('teknoloji') || n.includes('teknoloji') || n.includes('yabancı');
        if (cat === 'Değişken') return c.includes('değişken') || n.includes('değişken');
        if (cat === 'Serbest') return c.includes('serbest') || n.includes('serbest');
        return true;
      });
      setSearchResults(filtered);
    }
  };

  const handleSearch = (q: string) => {
    setSearchQuery(q);
    filterResults(q, selectedCategory);
  };

  const handleCategoryChange = (cat: string) => {
    setSelectedCategory(cat);
    filterResults(searchQuery, cat);
  };

  const handleSelectFundCode = async (code: string) => {
    const fund = await MarketDataService.getFundDetail(code);
    setSelectedFund(fund);
    setIsModalOpen(true);
    StorageService.setLastFundCode(code);
  };

  const handleDeleteTransaction = (id: string) => {
    if (window.confirm('Bu fon işlemini silmek istediğinize emin misiniz?')) {
      StorageService.deleteFundTransaction(id);
      loadData();
    }
  };

  const toggleFav = (code: string, e: React.MouseEvent) => {
    e.stopPropagation();
    StorageService.toggleFundFavorite(code);
    setFavorites(StorageService.getFundFavorites());
  };

  const totalFundValue = holdings.reduce((sum, h) => sum + h.currentValue, 0);
  const totalFundCost = holdings.reduce((sum, h) => sum + h.costValue, 0);
  const totalProfitLoss = totalFundValue - totalFundCost;
  const totalProfitLossPercent = totalFundCost > 0 ? (totalProfitLoss / totalFundCost) * 100 : 0;
  const totalDailyChange = holdings.reduce((sum, h) => sum + h.dailyChangeValue, 0);

  return (
    <div className="space-y-5 pb-24 animate-in fade-in duration-200">
      {/* Sub Tabs */}
      <div className="flex items-center justify-between border-b border-slate-800 pb-2">
        <div className="flex gap-1.5 overflow-x-auto">
          {[
            { id: 'portfolio', label: 'Portföyüm' },
            { id: 'search', label: 'Fon Ara & TEFAS' },
            { id: 'transactions', label: 'İşlemler' },
            { id: 'favorites', label: 'Favoriler' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-3.5 py-1.5 text-xs sm:text-sm font-semibold rounded-xl transition whitespace-nowrap ${
                activeTab === tab.id
                  ? 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <button
          onClick={() => onOpenTransaction()}
          className="px-3 py-1.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold text-xs transition flex items-center gap-1.5 shadow-md shadow-cyan-500/20 whitespace-nowrap"
        >
          <PlusCircle className="w-3.5 h-3.5" />
          İşlem Ekle
        </button>
      </div>

      {/* PORTFOLIO TAB */}
      {activeTab === 'portfolio' && (
        <div className="space-y-4">
          {/* Summary Card */}
          <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-cyan-400 uppercase tracking-wider flex items-center gap-1.5">
                <Layers className="w-4 h-4" />
                Toplam Fon Portföy Değeri
              </span>
              <span className="text-xs text-slate-400 font-medium">{holdings.length} Fon Pozisyonu</span>
            </div>

            <div className="text-3xl font-extrabold text-white font-mono">
              {AppFormatters.currency(totalFundValue)}
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
                  {AppFormatters.currency(totalFundCost)}
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
              Fon Pozisyonlarım
            </h3>

            {holdings.length === 0 ? (
              <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400 space-y-3">
                <Layers className="w-10 h-10 mx-auto text-slate-600" />
                <p className="text-sm">Henüz portföyünüzde fon bulunmuyor.</p>
                <button
                  onClick={() => onOpenTransaction()}
                  className="px-4 py-2 bg-cyan-500 text-slate-950 font-bold rounded-xl text-xs"
                >
                  Fon Alışı Ekle
                </button>
              </div>
            ) : (
              holdings.map((h) => (
                <div
                  key={h.fundCode}
                  onClick={() => handleSelectFundCode(h.fundCode)}
                  className="p-4 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 hover:border-cyan-500/40 transition cursor-pointer flex flex-col sm:flex-row sm:items-center justify-between gap-3 group"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-11 h-11 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400 font-extrabold text-sm">
                      {h.fundCode}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white text-base group-hover:text-cyan-400 transition">
                          {h.fundCode}
                        </span>
                        <span className="text-[11px] px-2 py-0.5 rounded bg-slate-800 text-slate-300">
                          {AppFormatters.percent(h.portfolioSharePercent)} pay
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 line-clamp-1 max-w-xs sm:max-w-sm mt-0.5">
                        {h.name}
                      </div>
                      <div className="text-[11px] text-slate-500 mt-1">
                        {AppFormatters.number(h.quantity, 0)} pay • Fiyat: {AppFormatters.currency(h.currentPrice)} • Ort: {AppFormatters.currency(h.averageCost)}
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

      {/* SEARCH TAB */}
      {activeTab === 'search' && (
        <div className="space-y-4">
          {/* Search Box */}
          <div className="relative">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => handleSearch(e.target.value)}
              placeholder="Fon Kodu (örn. KZL, AFT, TI3, MAC) veya Kurum/Fon Adı..."
              className="w-full pl-11 pr-4 py-3 bg-[#141824] border border-slate-700/80 rounded-2xl text-white placeholder-slate-500 text-sm focus:outline-none focus:border-cyan-500 shadow-inner"
            />
          </div>

          {/* Category Chips */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs scrollbar-none">
            {['Tümü', 'Katılım', 'Hisse', 'Para Piyasası', 'Altın & Emtia', 'Yabancı & Teknoloji', 'Değişken', 'Serbest'].map((cat) => (
              <button
                key={cat}
                onClick={() => handleCategoryChange(cat)}
                className={`px-3 py-1.5 rounded-xl font-medium transition whitespace-nowrap text-xs ${
                  selectedCategory === cat
                    ? 'bg-cyan-500 text-slate-950 font-bold shadow-sm shadow-cyan-500/30'
                    : 'bg-[#141824] text-slate-400 hover:text-white border border-slate-800 hover:border-slate-700'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* Quick Code Tags & Found Count */}
          <div className="flex items-center justify-between text-xs text-slate-500">
            <div className="flex items-center gap-1.5 overflow-x-auto">
              <span className="whitespace-nowrap">Popüler:</span>
              {['KLU', 'KZL', 'TTE', 'MAC', 'TI2', 'AFT', 'YAY', 'NNF', 'GTA', 'TCD'].map((code) => (
                <button
                  key={code}
                  onClick={() => handleSelectFundCode(code)}
                  className="px-2 py-0.5 rounded-md bg-[#141824] hover:bg-cyan-500/10 border border-slate-800 hover:border-cyan-500/40 text-cyan-400 font-semibold font-mono text-[11px]"
                >
                  {code}
                </button>
              ))}
            </div>
            <span className="whitespace-nowrap font-medium text-slate-400 ml-2">
              {searchResults.length} Fon Bulundu
            </span>
          </div>

          {/* Search Results Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {searchResults.map((f) => {
              const isFav = favorites.includes(f.code);
              return (
                <div
                  key={f.code}
                  onClick={() => handleSelectFundCode(f.code)}
                  className="p-4 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 hover:border-cyan-500/40 transition cursor-pointer flex items-center justify-between gap-3 group shadow-sm"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-11 h-11 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex flex-col items-center justify-center text-cyan-400 font-bold text-xs flex-shrink-0">
                      <span>{f.code}</span>
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white text-sm group-hover:text-cyan-400 transition">
                          {f.code}
                        </span>
                        {f.category && (
                          <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-800 text-slate-400 font-medium truncate max-w-[120px]">
                            {f.category}
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-slate-400 truncate max-w-[180px] sm:max-w-xs mt-0.5">
                        {f.name}
                      </div>
                      <div className="text-xs font-mono text-slate-200 mt-1 font-bold">
                        {AppFormatters.currency(f.currentPrice)}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 flex-shrink-0">
                    <div
                      className={`text-xs font-bold px-2 py-1 rounded-lg ${
                        f.return1Y >= 0 ? 'bg-emerald-500/15 text-emerald-400' : 'bg-red-500/15 text-red-400'
                      }`}
                    >
                      {AppFormatters.signedPercent(f.return1Y)}
                    </div>
                    <button
                      onClick={(e) => toggleFav(f.code, e)}
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
              Fon Alım / Satım Geçmişi ({transactions.length})
            </span>
          </div>

          {transactions.length === 0 ? (
            <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400">
              Henüz fon işlemi kaydedilmemiş.
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
                        <span className="font-bold text-white text-sm font-mono">{tx.fundCode}</span>
                        <span
                          className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                            tx.type === 'BUY' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'
                          }`}
                        >
                          {tx.type === 'BUY' ? 'ALIŞ' : 'SATIŞ'}
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 mt-0.5">
                        {AppFormatters.number(tx.quantity, 0)} pay • {AppFormatters.currency(tx.unitPrice)}
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
            Favori Fonlarım ({favorites.length})
          </span>

          {favorites.length === 0 ? (
            <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400">
              Henüz favori fon eklenmemiş. Arama sekmesinden yıldız ikonuna tıklayarak favorilere ekleyebilirsiniz.
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {favorites.map((code) => {
                const info = MarketDataService.searchFunds(code)[0];
                return (
                  <div
                    key={code}
                    onClick={() => handleSelectFundCode(code)}
                    className="p-4 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 hover:border-cyan-500/40 transition cursor-pointer flex items-center justify-between gap-3 group"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400 font-bold text-sm">
                        {code}
                      </div>
                      <div>
                        <div className="font-bold text-white text-sm group-hover:text-cyan-400 transition">
                          {code}
                        </div>
                        <div className="text-xs text-slate-400 line-clamp-1 max-w-[160px]">
                          {info?.name || `${code} Fonu`}
                        </div>
                        <div className="text-xs font-mono text-slate-300 mt-1 font-semibold">
                          {AppFormatters.currency(info?.currentPrice || 1.0)}
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={(e) => toggleFav(code, e)}
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

      {/* Fund Detail Modal */}
      <FundDetailModal
        fund={selectedFund}
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onOpenTransaction={(code, price) => {
          setIsModalOpen(false);
          onOpenTransaction(code, price);
        }}
      />
    </div>
  );
};
