export type TransactionType = 'BUY' | 'SELL';

export interface Fund {
  code: string;
  name: string;
  category: string;
  currentPrice: number;
  previousClose?: number;
  return1Y: number;
  realReturn1Y: number;
  riskScore: number;
  sharpe90: number;
}

export interface HistoryPoint {
  date: string;
  price: number;
}

export interface Stock {
  symbol: string;
  name: string;
  sector: string;
  currentPrice: number;
  previousClose?: number;
  dayHigh?: number;
  dayLow?: number;
  marketCap?: string;
  peRatio?: number;
  eps?: number;
  changePercent?: number;
}

export type FxAssetType = 'currency' | 'commodity' | 'crypto';

export interface FxAsset {
  id: string;
  name: string;
  symbol: string;
  currentPrice: number;
  changePercent: number;
  dayHigh: number;
  dayLow: number;
  type: FxAssetType;
}

export interface FundTransaction {
  id: string;
  fundCode: string;
  date: string;
  type: TransactionType;
  quantity: number;
  unitPrice: number;
  createdAt: number;
}

export interface StockTransaction {
  id: string;
  stockSymbol: string;
  date: string;
  type: TransactionType;
  quantity: number;
  unitPrice: number;
  createdAt: number;
}

export interface Holding {
  fundCode: string;
  name?: string;
  quantity: number;
  averageCost: number;
  currentPrice: number;
  currentValue: number;
  costValue: number;
  profitLoss: number;
  profitLossPercent: number;
  portfolioSharePercent: number;
  dailyChangePercent: number;
  dailyChangeValue: number;
}

export interface StockHolding {
  stockSymbol: string;
  name?: string;
  quantity: number;
  averageCost: number;
  currentPrice: number;
  currentValue: number;
  costValue: number;
  profitLoss: number;
  profitLossPercent: number;
  portfolioSharePercent: number;
  dailyChangePercent: number;
  dailyChangeValue: number;
}

export interface Debt {
  id: string;
  description: string;
  amount: number;
  createdAt: number;
}

export interface NoteItem {
  id: string;
  title: string;
  content: string;
  createdAt: string;
}

export interface PerformanceRecord {
  date: string;
  portfolioValue: number;
}

export interface PerformanceEntry {
  id: string;
  date: string;
  actualValue: number;
  targetValue: number;
  note?: string;
}

export interface DataSourceSettings {
  fundProvider: string;
  fundApiKey: string;
  stockApiUrl: string;
  stockApiKey: string;
  stockAppendDotIs: boolean;
  fxProvider: string;
  fxApiKey: string;
}

export interface AppSettings {
  fonolojiApiKey: string;
  twelveDataApiKey: string;
  exchangeRateApiKey: string;
  fundProvider?: string;
  stockApiUrl?: string;
  stockAppendDotIs?: boolean;
  fxProvider?: string;
  theme: 'dark' | 'light';
  currency: 'TRY' | 'USD';
}

export type ExpertRuleCategory =
  | 'Risk Yönetimi'
  | 'Giriş ve Çıkış Stratejisi'
  | 'Parite & Volatilite'
  | 'Zaman Dilimi & Seanslar'
  | 'Psikoloji & Disiplin'
  | 'Genel Kural';

export interface ExpertRule {
  id: string;
  title: string;
  rule: string;
  category: ExpertRuleCategory;
  createdAt: string;
  isActive: boolean;
  sourceContext?: string; // Where or why this rule was learned
}

export interface SupportResistanceZone {
  label: string;
  type: 'support' | 'resistance';
  price: number;
  strength?: 'high' | 'medium' | 'low';
}

export interface ExpertAnalysisSetup {
  id: string;
  pair: string;
  timeframe: string;
  action: 'BUY' | 'SELL' | 'BEKLE' | 'KAPAT';
  entryPrice: number;
  stopLoss: number;
  takeProfit1: number;
  takeProfit2?: number;
  riskRewardRatio?: string;
  zones?: SupportResistanceZone[];
  channel?: {
    trend: 'Yükseliş (Bullish)' | 'Düşüş (Bearish)' | 'Yatay (Range)';
    upperLine: number;
    lowerLine: number;
  };
  rationale: string;
  timestamp: string;
}

export interface ExpertChatMessage {
  id: string;
  sender: 'user' | 'expert';
  text: string;
  timestamp: string;
  analysisSetup?: ExpertAnalysisSetup;
  learnedRules?: ExpertRule[];
}

