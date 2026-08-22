import {
  FundTransaction,
  StockTransaction,
  Debt,
  NoteItem,
  PerformanceEntry,
  AppSettings,
  TransactionType,
  ExpertRule,
  ExpertChatMessage,
} from '../types';
import { FirebaseService, CloudPortfolioData } from './firebase';

const STORAGE_KEYS = {
  FUND_TRANSACTIONS: 'fontakip_fund_transactions',
  STOCK_TRANSACTIONS: 'fontakip_stock_transactions',
  FUND_FAVORITES: 'fontakip_fund_favorites',
  STOCK_FAVORITES: 'fontakip_stock_favorites',
  FX_FAVORITES: 'fontakip_fx_favorites',
  DEBTS: 'fontakip_debts',
  NOTES: 'tools.notes.items',
  PERFORMANCE: 'fontakip_performance',
  PERFORMANCE_TARGET_GROWTH: 'performance.targetGrowth',
  PERFORMANCE_RECORDS: 'performance.records',
  PLANNER: 'fontakip_planner_prefs',
  BALANCER: 'fontakip_balancer_prefs',
  COMPOUND: 'fontakip_compound_prefs',
  SETTINGS: 'fontakip_settings',
  LAST_FUND_CODE: 'last_fund_code',
  LAST_STOCK_SYMBOL: 'last_stock_symbol',
  EXPERT_RULES: 'fontakip_expert_rules',
  EXPERT_CHAT: 'fontakip_expert_chat_history',
};

export const defaultExpertRules: ExpertRule[] = [
  {
    id: 'rule-1',
    title: 'Sermaye Başına Maksimum Risk (%1-%2)',
    rule: 'Hiçbir FX işleminde toplam hesap bakiyesinin %2 sinden fazlası riske edilmemelidir. Lot boyutu daima Stop Loss pip mesafesine göre hesaplanır.',
    category: 'Risk Yönetimi',
    createdAt: new Date().toISOString(),
    isActive: true,
    sourceContext: 'Temel Risk Prensibi',
  },
  {
    id: 'rule-2',
    title: 'Minimum 1:2 Risk / Ödül Oranı',
    rule: 'Beklenen kâr potansiyeli (TP) göze alınan zararın (SL) en az 2 katı (1:2 R:R) olmadığı sürece işleme girilmez.',
    category: 'Giriş ve Çıkış Stratejisi',
    createdAt: new Date().toISOString(),
    isActive: true,
    sourceContext: 'Stratejik Giriş Filtresi',
  },
  {
    id: 'rule-3',
    title: 'GBPCAD & Londra-New York Seans Kuralı',
    rule: 'GBPCAD ve GBP/CAD çaprazlarında en yüksek likidite ve temiz trend hareketleri Londra Açılışı (10:00-13:00 TSİ) ve Londra-New York çakışmasında (15:30-18:30 TSİ) oluşur. Düşük likiditeli Asya seansında işlem açmaktan kaçınılır.',
    category: 'Zaman Dilimi & Seanslar',
    createdAt: new Date().toISOString(),
    isActive: true,
    sourceContext: 'Volatilite & Likidite Optimizasyonu',
  },
  {
    id: 'rule-4',
    title: 'Kritik Haber Öncesi Pozisyon Koruması',
    rule: 'İngiltere (BOE Faiz, CPI) ve Kanada (BOC Faiz, İstihdam/NFP) yüksek etkili haberlerinden 15 dakika önce ve sonra yeni piyasa emri açılmaz; mevcut kârlı işlemler başa baş (Breakeven) noktasına çekilir.',
    category: 'Parite & Volatilite',
    createdAt: new Date().toISOString(),
    isActive: true,
    sourceContext: 'Haber & Spread Koruma',
  },
  {
    id: 'rule-5',
    title: 'İntikam İşlemlerini Yasakla (Revenge Trading)',
    rule: 'Arka arkaya 2 Stop Loss alındığında o gün için o paritede işlem sonlandırılır ve grafik kapatılarak duygusal karar alınması engellenir.',
    category: 'Psikoloji & Disiplin',
    createdAt: new Date().toISOString(),
    isActive: true,
    sourceContext: 'Psikolojik Sermaye Koruma',
  },
];


export const defaultSettings: AppSettings = {
  fonolojiApiKey: 'fon_rFKqxTJAur2tAFL_Y_brdrmuahKpVpPX',
  twelveDataApiKey: '',
  exchangeRateApiKey: '',
  fundProvider: 'https://fonoloji.com/v1/funds',
  stockApiUrl: 'https://api.twelvedata.com/price',
  stockAppendDotIs: false,
  fxProvider: 'https://v6.exchangerate-api.com/v6/',
  theme: 'dark',
  currency: 'TRY',
};

// Helper: Convert timestamp (milliseconds or ISO) to YYYY-MM-DD
function formatDateValue(val: any): string {
  if (!val) return new Date().toISOString().split('T')[0];
  if (typeof val === 'number') {
    const ms = val < 10000000000 ? val * 1000 : val;
    return new Date(ms).toISOString().split('T')[0];
  }
  if (typeof val === 'string') {
    if (val.includes('T')) return val.split('T')[0];
    if (val.length === 10 && val.includes('-')) return val;
    const num = Number(val);
    if (!isNaN(num) && num > 0) {
      const ms = num < 10000000000 ? num * 1000 : num;
      return new Date(ms).toISOString().split('T')[0];
    }
    return val;
  }
  return new Date().toISOString().split('T')[0];
}

// Initialize clean empty data
export function initSeedDataIfEmpty(): void {
  // Do not add dummy data. If key doesn't exist, leave it empty or initialize with empty array.
  if (!localStorage.getItem(STORAGE_KEYS.FUND_TRANSACTIONS)) {
    localStorage.setItem(STORAGE_KEYS.FUND_TRANSACTIONS, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.STOCK_TRANSACTIONS)) {
    localStorage.setItem(STORAGE_KEYS.STOCK_TRANSACTIONS, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.FUND_FAVORITES)) {
    localStorage.setItem(STORAGE_KEYS.FUND_FAVORITES, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.STOCK_FAVORITES)) {
    localStorage.setItem(STORAGE_KEYS.STOCK_FAVORITES, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.FX_FAVORITES)) {
    localStorage.setItem(STORAGE_KEYS.FX_FAVORITES, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.DEBTS)) {
    localStorage.setItem(STORAGE_KEYS.DEBTS, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.NOTES)) {
    localStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify([]));
  }
  if (!localStorage.getItem(STORAGE_KEYS.PERFORMANCE)) {
    localStorage.setItem(STORAGE_KEYS.PERFORMANCE, JSON.stringify([]));
  }
}

export const StorageService = {
  // Fund Transactions
  getFundTransactions(): FundTransaction[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.FUND_TRANSACTIONS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  saveFundTransactions(transactions: FundTransaction[]): void {
    localStorage.setItem(STORAGE_KEYS.FUND_TRANSACTIONS, JSON.stringify(transactions));
  },

  addFundTransaction(tx: Omit<FundTransaction, 'id' | 'createdAt'>): FundTransaction {
    const list = this.getFundTransactions();
    const newTx: FundTransaction = {
      ...tx,
      id: 'fund-tx-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
      createdAt: Date.now(),
    };
    list.unshift(newTx);
    this.saveFundTransactions(list);
    return newTx;
  },

  deleteFundTransaction(id: string): void {
    const list = this.getFundTransactions().filter((item) => item.id !== id);
    this.saveFundTransactions(list);
  },

  // Stock Transactions
  getStockTransactions(): StockTransaction[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.STOCK_TRANSACTIONS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  saveStockTransactions(transactions: StockTransaction[]): void {
    localStorage.setItem(STORAGE_KEYS.STOCK_TRANSACTIONS, JSON.stringify(transactions));
  },

  addStockTransaction(tx: Omit<StockTransaction, 'id' | 'createdAt'>): StockTransaction {
    const list = this.getStockTransactions();
    const newTx: StockTransaction = {
      ...tx,
      id: 'stock-tx-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
      createdAt: Date.now(),
    };
    list.unshift(newTx);
    this.saveStockTransactions(list);
    return newTx;
  },

  deleteStockTransaction(id: string): void {
    const list = this.getStockTransactions().filter((item) => item.id !== id);
    this.saveStockTransactions(list);
  },

  // Favorites
  getFundFavorites(): string[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.FUND_FAVORITES);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  toggleFundFavorite(code: string): boolean {
    const list = this.getFundFavorites();
    const normalized = code.toUpperCase().trim();
    const exists = list.includes(normalized);
    const updated = exists ? list.filter((c) => c !== normalized) : [...list, normalized];
    localStorage.setItem(STORAGE_KEYS.FUND_FAVORITES, JSON.stringify(updated));
    return !exists;
  },

  getStockFavorites(): string[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.STOCK_FAVORITES);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  toggleStockFavorite(symbol: string): boolean {
    const list = this.getStockFavorites();
    const normalized = symbol.toUpperCase().trim();
    const exists = list.includes(normalized);
    const updated = exists ? list.filter((s) => s !== normalized) : [...list, normalized];
    localStorage.setItem(STORAGE_KEYS.STOCK_FAVORITES, JSON.stringify(updated));
    return !exists;
  },

  getFxFavorites(): string[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.FX_FAVORITES);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  toggleFxFavorite(id: string): boolean {
    const list = this.getFxFavorites();
    const normalized = id.toUpperCase().trim();
    const exists = list.includes(normalized);
    const updated = exists ? list.filter((s) => s !== normalized) : [...list, normalized];
    localStorage.setItem(STORAGE_KEYS.FX_FAVORITES, JSON.stringify(updated));
    return !exists;
  },

  // Debts
  getDebts(): Debt[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.DEBTS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  addDebt(description: string, amount: number): Debt {
    const list = this.getDebts();
    const newDebt: Debt = {
      id: 'debt-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
      description,
      amount,
      createdAt: Date.now(),
    };
    list.unshift(newDebt);
    localStorage.setItem(STORAGE_KEYS.DEBTS, JSON.stringify(list));
    return newDebt;
  },

  deleteDebt(id: string): void {
    const list = this.getDebts().filter((d) => d.id !== id);
    localStorage.setItem(STORAGE_KEYS.DEBTS, JSON.stringify(list));
  },

  // Notes
  getNotes(): NoteItem[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.NOTES);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  saveNotes(notes: NoteItem[]): void {
    localStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));
  },

  addNote(title: string, content: string): NoteItem {
    const list = this.getNotes();
    const newNote: NoteItem = {
      id: 'note-' + Date.now(),
      title,
      content,
      createdAt: new Date().toISOString(),
    };
    list.unshift(newNote);
    this.saveNotes(list);
    return newNote;
  },

  updateNote(id: string, title: string, content: string): void {
    const list = this.getNotes().map((n) => (n.id === id ? { ...n, title, content } : n));
    this.saveNotes(list);
  },

  deleteNote(id: string): void {
    const list = this.getNotes().filter((n) => n.id !== id);
    this.saveNotes(list);
  },

  // Performance
  getPerformance(): PerformanceEntry[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.PERFORMANCE);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  savePerformance(list: PerformanceEntry[]): void {
    localStorage.setItem(STORAGE_KEYS.PERFORMANCE, JSON.stringify(list));
  },

  addPerformanceEntry(entry: Omit<PerformanceEntry, 'id'>): PerformanceEntry {
    const list = this.getPerformance();
    const newEntry: PerformanceEntry = {
      ...entry,
      id: 'perf-' + Date.now(),
    };
    list.push(newEntry);
    list.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    this.savePerformance(list);
    return newEntry;
  },

  deletePerformanceEntry(id: string): void {
    const list = this.getPerformance().filter((p) => p.id !== id);
    this.savePerformance(list);
  },

  // Performance Tracking (Flutter/Original Format)
  getTargetGrowth(): string {
    return localStorage.getItem(STORAGE_KEYS.PERFORMANCE_TARGET_GROWTH) || '';
  },

  saveTargetGrowth(val: string): void {
    localStorage.setItem(STORAGE_KEYS.PERFORMANCE_TARGET_GROWTH, val);
  },

  getPerformanceRecords(): Array<{ date: string; portfolioValue: number }> {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.PERFORMANCE_RECORDS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  savePerformanceRecords(records: Array<{ date: string; portfolioValue: number }>): void {
    localStorage.setItem(STORAGE_KEYS.PERFORMANCE_RECORDS, JSON.stringify(records));
  },

  addPerformanceRecord(date: string, portfolioValue: number): void {
    const records = this.getPerformanceRecords();
    records.push({ date, portfolioValue });
    this.savePerformanceRecords(records);
  },

  deleteLastPerformanceRecord(): void {
    const records = this.getPerformanceRecords();
    if (records.length > 0) {
      records.pop();
      this.savePerformanceRecords(records);
    }
  },

  // Settings & API Keys
  getSettings(): AppSettings {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.SETTINGS);
      return data ? { ...defaultSettings, ...JSON.parse(data) } : defaultSettings;
    } catch {
      return defaultSettings;
    }
  },

  saveSettings(settings: AppSettings): void {
    localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
  },

  getApiKeys() {
    const s = this.getSettings();
    return {
      fonolojiKey: s.fonolojiApiKey || '',
      twelveDataKey: s.twelveDataApiKey || '',
      exchangeRateApiKey: s.exchangeRateApiKey || '',
    };
  },

  saveApiKeys(keys: { 
    fonolojiKey?: string; 
    twelveDataKey?: string; 
    exchangeRateApiKey?: string;
    fundProvider?: string;
    stockApiUrl?: string;
    stockAppendDotIs?: boolean;
    fxProvider?: string;
  }) {
    const s = this.getSettings();
    this.saveSettings({
      ...s,
      fonolojiApiKey: keys.fonolojiKey ?? s.fonolojiApiKey,
      twelveDataApiKey: keys.twelveDataKey ?? s.twelveDataApiKey,
      exchangeRateApiKey: keys.exchangeRateApiKey ?? s.exchangeRateApiKey,
      fundProvider: keys.fundProvider ?? s.fundProvider,
      stockApiUrl: keys.stockApiUrl ?? s.stockApiUrl,
      stockAppendDotIs: keys.stockAppendDotIs ?? s.stockAppendDotIs,
      fxProvider: keys.fxProvider ?? s.fxProvider,
    });
  },

  // Last codes
  getLastFundCode(): string {
    return localStorage.getItem(STORAGE_KEYS.LAST_FUND_CODE) || '';
  },

  setLastFundCode(code: string): void {
    localStorage.setItem(STORAGE_KEYS.LAST_FUND_CODE, code.toUpperCase());
  },

  getLastStockSymbol(): string {
    return localStorage.getItem(STORAGE_KEYS.LAST_STOCK_SYMBOL) || '';
  },

  setLastStockSymbol(symbol: string): void {
    localStorage.setItem(STORAGE_KEYS.LAST_STOCK_SYMBOL, symbol.toUpperCase());
  },

  // Cloud Sync Utilities
  getAllDataForSync(): CloudPortfolioData {
    return {
      fundTransactions: this.getFundTransactions(),
      stockTransactions: this.getStockTransactions(),
      fundFavorites: this.getFundFavorites(),
      stockFavorites: this.getStockFavorites(),
      fxFavorites: this.getFxFavorites(),
      debts: this.getDebts(),
      notes: this.getNotes(),
      performance: this.getPerformance(),
      performanceRecords: this.getPerformanceRecords(),
      performanceTargetGrowth: this.getTargetGrowth(),
      settings: this.getSettings(),
      updatedAt: new Date().toISOString(),
    };
  },

  applyCloudData(data: CloudPortfolioData): void {
    if (data.fundTransactions && Array.isArray(data.fundTransactions)) {
      localStorage.setItem(STORAGE_KEYS.FUND_TRANSACTIONS, JSON.stringify(data.fundTransactions));
    }
    if (data.stockTransactions && Array.isArray(data.stockTransactions)) {
      localStorage.setItem(STORAGE_KEYS.STOCK_TRANSACTIONS, JSON.stringify(data.stockTransactions));
    }
    if (data.fundFavorites && Array.isArray(data.fundFavorites)) {
      localStorage.setItem(STORAGE_KEYS.FUND_FAVORITES, JSON.stringify(data.fundFavorites));
    }
    if (data.stockFavorites && Array.isArray(data.stockFavorites)) {
      localStorage.setItem(STORAGE_KEYS.STOCK_FAVORITES, JSON.stringify(data.stockFavorites));
    }
    if (data.fxFavorites && Array.isArray(data.fxFavorites)) {
      localStorage.setItem(STORAGE_KEYS.FX_FAVORITES, JSON.stringify(data.fxFavorites));
    }
    if (data.debts && Array.isArray(data.debts)) {
      localStorage.setItem(STORAGE_KEYS.DEBTS, JSON.stringify(data.debts));
    }
    if (data.notes && Array.isArray(data.notes)) {
      localStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(data.notes));
    }
    if (data.performance && Array.isArray(data.performance)) {
      localStorage.setItem(STORAGE_KEYS.PERFORMANCE, JSON.stringify(data.performance));
    }
    if (data.performanceRecords && Array.isArray(data.performanceRecords)) {
      localStorage.setItem(STORAGE_KEYS.PERFORMANCE_RECORDS, JSON.stringify(data.performanceRecords));
    }
    if (typeof data.performanceTargetGrowth === 'string') {
      localStorage.setItem(STORAGE_KEYS.PERFORMANCE_TARGET_GROWTH, data.performanceTargetGrowth);
    }
    if (data.settings && typeof data.settings === 'object') {
      this.saveSettings({ ...this.getSettings(), ...data.settings });
    }
  },

  // Import from JSON (Handles Flutter Export format, SharedPreferences, API keys, and Web backup format)
  importRawJsonBackup(rawText: string): { success: boolean; countInfo: string } {
    try {
      const parsed = JSON.parse(rawText);
      let fundTx: FundTransaction[] = [];
      let stockTx: StockTransaction[] = [];
      let fundFavs: string[] = [];
      let stockFavs: string[] = [];
      let debts: Debt[] = [];
      let notes: NoteItem[] = [];
      let performanceRecords: Array<{ date: string; portfolioValue: number }> = [];
      let targetGrowthVal: string | undefined;

      // API Key & URL extraction
      let extractedFundKey: string | undefined;
      let extractedStockKey: string | undefined;
      let extractedFxKey: string | undefined;
      let extractedFundProvider: string | undefined;
      let extractedStockApiUrl: string | undefined;
      let extractedStockAppendDotIs: boolean | undefined;
      let extractedFxProvider: string | undefined;

      // 1. Check SharedPreferences if present in Flutter backup
      if (parsed.sharedPreferences && typeof parsed.sharedPreferences === 'object') {
        const sp = parsed.sharedPreferences;
        if (sp['data_source.fund.api_key']) extractedFundKey = String(sp['data_source.fund.api_key']);
        if (sp['data_source.stock.api_key']) extractedStockKey = String(sp['data_source.stock.api_key']);
        if (sp['data_source.fx.api_key']) extractedFxKey = String(sp['data_source.fx.api_key']);
        if (sp['fonolojiApiKey']) extractedFundKey = String(sp['fonolojiApiKey']);
        if (sp['twelveDataApiKey']) extractedStockKey = String(sp['twelveDataApiKey']);
        if (sp['exchangeRateApiKey']) extractedFxKey = String(sp['exchangeRateApiKey']);

        if (sp['data_source.fund.provider']) extractedFundProvider = String(sp['data_source.fund.provider']);
        if (sp['data_source.stock.api_url']) extractedStockApiUrl = String(sp['data_source.stock.api_url']);
        if (sp['data_source.stock.provider'] && !extractedStockApiUrl) extractedStockApiUrl = String(sp['data_source.stock.provider']);
        if (sp['data_source.stock.append_dot_is'] !== undefined) {
          extractedStockAppendDotIs = Boolean(sp['data_source.stock.append_dot_is']);
        }
        if (sp['data_source.fx.provider']) extractedFxProvider = String(sp['data_source.fx.provider']);

        // Flutter Performance Records and Target Growth in SharedPreferences
        if (sp['performance.targetGrowth'] !== undefined) {
          targetGrowthVal = String(sp['performance.targetGrowth']);
        }
        if (sp['performance.records']) {
          try {
            const rawRecords = typeof sp['performance.records'] === 'string'
              ? JSON.parse(sp['performance.records'])
              : sp['performance.records'];
            if (Array.isArray(rawRecords)) {
              performanceRecords = rawRecords.map((r: any) => ({
                date: typeof r.date === 'string' ? r.date : new Date().toISOString(),
                portfolioValue: Number(r.portfolioValue || r.portfolio_value || 0),
              })).filter((r) => r.portfolioValue > 0 || r.date);
            }
          } catch (e) {
            console.warn('Could not parse performance.records from sharedPreferences:', e);
          }
        }
      }

      // Also check top-level or nested settings/apiKeys
      if (parsed.settings && typeof parsed.settings === 'object') {
        if (parsed.settings.fonolojiApiKey || parsed.settings.fundApiKey) {
          extractedFundKey = parsed.settings.fonolojiApiKey || parsed.settings.fundApiKey;
        }
        if (parsed.settings.twelveDataApiKey || parsed.settings.stockApiKey) {
          extractedStockKey = parsed.settings.twelveDataApiKey || parsed.settings.stockApiKey;
        }
        if (parsed.settings.exchangeRateApiKey || parsed.settings.fxApiKey) {
          extractedFxKey = parsed.settings.exchangeRateApiKey || parsed.settings.fxApiKey;
        }
        if (parsed.settings.fundProvider) extractedFundProvider = parsed.settings.fundProvider;
        if (parsed.settings.stockApiUrl) extractedStockApiUrl = parsed.settings.stockApiUrl;
        if (parsed.settings.stockAppendDotIs !== undefined) extractedStockAppendDotIs = parsed.settings.stockAppendDotIs;
        if (parsed.settings.fxProvider) extractedFxProvider = parsed.settings.fxProvider;
      }

      if (parsed.fonolojiApiKey || parsed.fundApiKey) extractedFundKey = parsed.fonolojiApiKey || parsed.fundApiKey;
      if (parsed.twelveDataApiKey || parsed.stockApiKey) extractedStockKey = parsed.twelveDataApiKey || parsed.stockApiKey;
      if (parsed.exchangeRateApiKey || parsed.fxApiKey) extractedFxKey = parsed.exchangeRateApiKey || parsed.fxApiKey;
      if (parsed.fundProvider) extractedFundProvider = parsed.fundProvider;
      if (parsed.stockApiUrl) extractedStockApiUrl = parsed.stockApiUrl;
      if (parsed.stockAppendDotIs !== undefined) extractedStockAppendDotIs = parsed.stockAppendDotIs;
      if (parsed.fxProvider) extractedFxProvider = parsed.fxProvider;

      if (parsed.targetGrowth || parsed.performanceTargetGrowth) {
        targetGrowthVal = String(parsed.targetGrowth || parsed.performanceTargetGrowth);
      }
      if (Array.isArray(parsed.performanceRecords)) {
        performanceRecords = parsed.performanceRecords;
      }

      // 2. Check if Flutter format (with "database" key)
      if (parsed.database && typeof parsed.database === 'object') {
        const db = parsed.database;

        // Fund Transactions
        if (Array.isArray(db.transactions)) {
          fundTx = db.transactions.map((t: any, idx: number): FundTransaction => ({
            id: t.id ? String(t.id) : `flutter-tx-${idx}`,
            fundCode: String(t.fund_code || t.fundCode || '').toUpperCase().trim(),
            date: formatDateValue(t.date),
            type: ((t.type || 'BUY').toUpperCase() === 'SELL' ? 'SELL' : 'BUY') as TransactionType,
            quantity: Number(t.quantity || 0),
            unitPrice: Number(t.unit_price || t.unitPrice || 0),
            createdAt: typeof t.created_at === 'number' ? t.created_at : Date.now(),
          })).filter((t: FundTransaction) => Boolean(t.fundCode) && t.quantity > 0);
        }

        // Stock Transactions
        if (Array.isArray(db.stock_transactions)) {
          stockTx = db.stock_transactions.map((t: any, idx: number): StockTransaction => ({
            id: t.id ? String(t.id) : `flutter-stock-tx-${idx}`,
            stockSymbol: String(t.stock_symbol || t.stockSymbol || '').toUpperCase().trim(),
            date: formatDateValue(t.date),
            type: ((t.type || 'BUY').toUpperCase() === 'SELL' ? 'SELL' : 'BUY') as TransactionType,
            quantity: Number(t.quantity || 0),
            unitPrice: Number(t.unit_price || t.unitPrice || 0),
            createdAt: typeof t.created_at === 'number' ? t.created_at : Date.now(),
          })).filter((t: StockTransaction) => Boolean(t.stockSymbol) && t.quantity > 0);
        }

        // Favorites
        if (Array.isArray(db.favorites)) {
          fundFavs = db.favorites
            .map((f: any) => (typeof f === 'string' ? f : f.code))
            .filter(Boolean)
            .map((c: string) => c.toUpperCase().trim());
        }

        if (Array.isArray(db.stock_favorites)) {
          stockFavs = db.stock_favorites
            .map((f: any) => (typeof f === 'string' ? f : f.code))
            .filter(Boolean)
            .map((c: string) => c.toUpperCase().trim());
        }

        // Debts
        if (Array.isArray(db.debts)) {
          debts = db.debts.map((d: any, idx: number) => ({
            id: d.id ? String(d.id) : `debt-${idx}`,
            description: String(d.description || 'Borç'),
            amount: Number(d.amount || 0),
            createdAt: typeof d.created_at === 'number' ? d.created_at : Date.now(),
          }));
        }
      } 
      // 3. Direct Web format or combined object
      else {
        if (Array.isArray(parsed.fundTransactions)) fundTx = parsed.fundTransactions;
        if (Array.isArray(parsed.stockTransactions)) stockTx = parsed.stockTransactions;
        if (Array.isArray(parsed.fundFavorites)) fundFavs = parsed.fundFavorites;
        if (Array.isArray(parsed.stockFavorites)) stockFavs = parsed.stockFavorites;
        if (Array.isArray(parsed.debts)) debts = parsed.debts;
        if (Array.isArray(parsed.notes)) notes = parsed.notes;

        // If it's a direct array of fund transactions
        if (Array.isArray(parsed) && parsed.length > 0) {
          fundTx = parsed.map((t: any, idx: number): FundTransaction => ({
            id: t.id || `imported-tx-${idx}`,
            fundCode: (t.fundCode || t.fund_code || '').toUpperCase().trim(),
            date: formatDateValue(t.date),
            type: ((t.type || 'BUY').toUpperCase() === 'SELL' ? 'SELL' : 'BUY') as TransactionType,
            quantity: Number(t.quantity || 0),
            unitPrice: Number(t.unitPrice || t.unit_price || 0),
            createdAt: t.createdAt || Date.now(),
          })).filter((t: FundTransaction) => Boolean(t.fundCode));
        }
      }

      // Apply to LocalStorage
      if (fundTx.length > 0) this.saveFundTransactions(fundTx);
      if (stockTx.length > 0) this.saveStockTransactions(stockTx);
      if (fundFavs.length > 0) localStorage.setItem(STORAGE_KEYS.FUND_FAVORITES, JSON.stringify(fundFavs));
      if (stockFavs.length > 0) localStorage.setItem(STORAGE_KEYS.STOCK_FAVORITES, JSON.stringify(stockFavs));
      if (debts.length > 0) localStorage.setItem(STORAGE_KEYS.DEBTS, JSON.stringify(debts));
      if (notes.length > 0) this.saveNotes(notes);
      if (performanceRecords.length > 0) this.savePerformanceRecords(performanceRecords);
      if (targetGrowthVal !== undefined) this.saveTargetGrowth(targetGrowthVal);

      // Save extracted API keys & data source URLs
      let apiCount = 0;
      if (
        extractedFundKey ||
        extractedStockKey ||
        extractedFxKey ||
        extractedStockApiUrl ||
        extractedFundProvider ||
        extractedFxProvider ||
        extractedStockAppendDotIs !== undefined
      ) {
        this.saveApiKeys({
          fonolojiKey: extractedFundKey,
          twelveDataKey: extractedStockKey,
          exchangeRateApiKey: extractedFxKey,
          fundProvider: extractedFundProvider,
          stockApiUrl: extractedStockApiUrl,
          stockAppendDotIs: extractedStockAppendDotIs,
          fxProvider: extractedFxProvider,
        });
        if (extractedFundKey) apiCount++;
        if (extractedStockKey) apiCount++;
        if (extractedFxKey) apiCount++;
        if (extractedStockApiUrl) apiCount++;
      }

      const extraItems: string[] = [];
      if (performanceRecords.length > 0) extraItems.push(`${performanceRecords.length} Performans Kaydı`);
      if (apiCount > 0) extraItems.push(`${apiCount} API Anahtarı`);

      const countInfo = `${fundTx.length} Fon İşlemi, ${stockTx.length} Hisse İşlemi, ${fundFavs.length + stockFavs.length} Favori, ${debts.length} Borç Kaydı${extraItems.length > 0 ? `, ${extraItems.join(', ')}` : ''}`;
      return { success: true, countInfo };
    } catch (e: any) {
      console.error('Import parse error:', e);
      return { success: false, countInfo: e.message || 'Geçersiz JSON formatı' };
    }
  },

  clearAllData(): void {
    localStorage.setItem(STORAGE_KEYS.FUND_TRANSACTIONS, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.STOCK_TRANSACTIONS, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.FUND_FAVORITES, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.STOCK_FAVORITES, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.FX_FAVORITES, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.DEBTS, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.PERFORMANCE, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.PERFORMANCE_RECORDS, JSON.stringify([]));
    localStorage.removeItem(STORAGE_KEYS.PERFORMANCE_TARGET_GROWTH);
    localStorage.removeItem(STORAGE_KEYS.LAST_FUND_CODE);
    localStorage.removeItem(STORAGE_KEYS.LAST_STOCK_SYMBOL);
  },

  // Expert Rules & Knowledge Base
  getExpertRules(): ExpertRule[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.EXPERT_RULES);
      if (!data) {
        localStorage.setItem(STORAGE_KEYS.EXPERT_RULES, JSON.stringify(defaultExpertRules));
        return defaultExpertRules;
      }
      return JSON.parse(data);
    } catch {
      return defaultExpertRules;
    }
  },

  saveExpertRules(rules: ExpertRule[]): void {
    localStorage.setItem(STORAGE_KEYS.EXPERT_RULES, JSON.stringify(rules));
  },

  addExpertRule(rule: Omit<ExpertRule, 'id' | 'createdAt'>): ExpertRule {
    const list = this.getExpertRules();
    const newRule: ExpertRule = {
      ...rule,
      id: 'rule-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
      createdAt: new Date().toISOString(),
    };
    list.unshift(newRule);
    this.saveExpertRules(list);
    return newRule;
  },

  updateExpertRule(id: string, updates: Partial<ExpertRule>): void {
    const list = this.getExpertRules().map((r) => (r.id === id ? { ...r, ...updates } : r));
    this.saveExpertRules(list);
  },

  toggleExpertRule(id: string): void {
    const list = this.getExpertRules().map((r) => (r.id === id ? { ...r, isActive: !r.isActive } : r));
    this.saveExpertRules(list);
  },

  deleteExpertRule(id: string): void {
    const list = this.getExpertRules().filter((r) => r.id !== id);
    this.saveExpertRules(list);
  },

  // Expert Chat History
  getExpertChatHistory(): ExpertChatMessage[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.EXPERT_CHAT);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  },

  saveExpertChatHistory(messages: ExpertChatMessage[]): void {
    // Keep last 40 messages to avoid localstorage bloat
    const trimmed = messages.slice(-40);
    localStorage.setItem(STORAGE_KEYS.EXPERT_CHAT, JSON.stringify(trimmed));
  },

  clearExpertChatHistory(): void {
    localStorage.removeItem(STORAGE_KEYS.EXPERT_CHAT);
  },

  clearAll(): void {
    this.clearAllData();
  },
};

