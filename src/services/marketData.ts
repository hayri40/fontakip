import { Fund, Stock, FxAsset, HistoryPoint, Holding, StockHolding } from '../types';
import { StorageService } from './storage';
import { TEFAS_FUNDS_CATALOG, TefasFundInfo } from '../data/tefasFundsDatabase';

export const POPULAR_FUNDS: Record<string, Omit<Fund, 'code'>> = {
  KLU: {
    name: 'Kuveyt Türk Portföy Para Piyasası Katılım (TL) Fonu',
    category: 'Para Piyasası Katılım Fonu',
    currentPrice: 1.8540,
    previousClose: 1.8480,
    return1Y: 52.40,
    realReturn1Y: 14.20,
    riskScore: 1,
    sharpe90: 2.45,
  },
  KZL: {
    name: 'Kuveyt Türk Portföy Altın Katılım Fonu',
    category: 'Kıymetli Madenler Katılım Fonu',
    currentPrice: 0.2450,
    previousClose: 0.2428,
    return1Y: 73.40,
    realReturn1Y: 17.10,
    riskScore: 6,
    sharpe90: 2.10,
  },
  KTK: {
    name: 'Kuveyt Türk Portföy Kısa Vadeli Kira Sertifikaları Katılım Fonu',
    category: 'Kira Sertifikası Katılım Fonu',
    currentPrice: 2.3410,
    previousClose: 2.3380,
    return1Y: 48.90,
    realReturn1Y: 11.20,
    riskScore: 2,
    sharpe90: 2.15,
  },
  KTS: {
    name: 'Kuveyt Türk Portföy Katılım Hisse Senedi Fonu (Hisse Yoğun)',
    category: 'Hisse Senedi Katılım Fonu',
    currentPrice: 7.8920,
    previousClose: 7.8200,
    return1Y: 84.50,
    realReturn1Y: 26.30,
    riskScore: 6,
    sharpe90: 2.35,
  },
  TTE: {
    name: 'İş Portföy BIST Teknoloji Ağırlık Sınırlamalı Hisse Senedi Fonu',
    category: 'Hisse Senedi Fonu',
    currentPrice: 1.7678,
    previousClose: 1.7510,
    return1Y: 92.40,
    realReturn1Y: 34.60,
    riskScore: 7,
    sharpe90: 2.84,
  },
  MAC: {
    name: 'Marmara Capital Portföy Hisse Senedi (TL) Fonu (Hisse Yoğun)',
    category: 'Hisse Senedi Fonu',
    currentPrice: 0.7579,
    previousClose: 0.7510,
    return1Y: 81.20,
    realReturn1Y: 23.50,
    riskScore: 6,
    sharpe90: 2.45,
  },
  TI1: {
    name: 'İş Portföy Para Piyasası (TL) Fonu',
    category: 'Para Piyasası Fonu',
    currentPrice: 1.6658,
    previousClose: 1.6630,
    return1Y: 53.80,
    realReturn1Y: 15.10,
    riskScore: 1,
    sharpe90: 2.65,
  },
  TI2: {
    name: 'İş Portföy İkinci Değişken Fon',
    category: 'Değişken Şemsiye Fonu',
    currentPrice: 4.1205,
    previousClose: 4.0980,
    return1Y: 68.30,
    realReturn1Y: 12.40,
    riskScore: 5,
    sharpe90: 1.95,
  },
  AFT: {
    name: 'Ak Portföy Yeni Teknolojiler Yabancı Hisse Senedi Fonu',
    category: 'Yabancı Hisse Senedi Fonu',
    currentPrice: 0.3845,
    previousClose: 0.3792,
    return1Y: 88.60,
    realReturn1Y: 30.10,
    riskScore: 6,
    sharpe90: 2.50,
  },
  YAY: {
    name: 'Yapı Kredi Portföy Yabancı Teknoloji Sektörü Hisse Senedi Fonu',
    category: 'Yabancı Hisse Senedi Fonu',
    currentPrice: 2.4560,
    previousClose: 2.4210,
    return1Y: 85.10,
    realReturn1Y: 27.80,
    riskScore: 6,
    sharpe90: 2.38,
  },
  GMR: {
    name: 'Inveo Portföy İkinci Değişken Fon',
    category: 'Değişken Şemsiye Fonu',
    currentPrice: 3.1240,
    previousClose: 3.1020,
    return1Y: 71.40,
    realReturn1Y: 15.20,
    riskScore: 5,
    sharpe90: 1.88,
  },
  IPB: {
    name: 'İstanbul Portföy Birinci Değişken Fon',
    category: 'Değişken Şemsiye Fonu',
    currentPrice: 6.8240,
    previousClose: 6.7810,
    return1Y: 79.50,
    realReturn1Y: 21.90,
    riskScore: 6,
    sharpe90: 2.20,
  },
  GTA: {
    name: 'Garanti Portföy Altın Fonu',
    category: 'Kıymetli Madenler Fonu',
    currentPrice: 0.1824,
    previousClose: 0.1802,
    return1Y: 72.10,
    realReturn1Y: 16.30,
    riskScore: 6,
    sharpe90: 2.05,
  },
  TCD: {
    name: 'Tacirler Portföy Değişken Fon',
    category: 'Değişken Şemsiye Fonu',
    currentPrice: 14.8520,
    previousClose: 14.7100,
    return1Y: 96.30,
    realReturn1Y: 37.50,
    riskScore: 7,
    sharpe90: 2.92,
  },
  NNF: {
    name: 'Hedef Portföy Birinci Hisse Senedi Fonu (Hisse Yoğun)',
    category: 'Hisse Senedi Fonu',
    currentPrice: 4.9500,
    previousClose: 4.9120,
    return1Y: 87.60,
    realReturn1Y: 28.10,
    riskScore: 6,
    sharpe90: 2.35,
  },
  YAC: {
    name: 'Yapı Kredi Portföy Altın Fonu',
    category: 'Kıymetli Madenler Fonu',
    currentPrice: 0.1654,
    previousClose: 0.1639,
    return1Y: 71.90,
    realReturn1Y: 16.00,
    riskScore: 6,
    sharpe90: 2.02,
  },
};

export const BIST_STOCKS: Stock[] = [
  {
    symbol: 'THYAO',
    name: 'Türk Hava Yolları',
    sector: 'Ulaştırma',
    currentPrice: 312.50,
    previousClose: 308.25,
    dayHigh: 315.00,
    dayLow: 307.50,
    marketCap: '431.2 Mr ₺',
    peRatio: 3.42,
    eps: 91.37,
    changePercent: 1.38,
  },
  {
    symbol: 'ASELS',
    name: 'Aselsan',
    sector: 'Savunma Sanayi',
    currentPrice: 68.75,
    previousClose: 67.20,
    dayHigh: 69.40,
    dayLow: 66.80,
    marketCap: '313.5 Mr ₺',
    peRatio: 12.80,
    eps: 5.37,
    changePercent: 2.31,
  },
  {
    symbol: 'EREGL',
    name: 'Ereğli Demir Çelik',
    sector: 'Metal Ana Sanayi',
    currentPrice: 48.90,
    previousClose: 49.30,
    dayHigh: 49.80,
    dayLow: 48.50,
    marketCap: '171.1 Mr ₺',
    peRatio: 14.20,
    eps: 3.44,
    changePercent: -0.81,
  },
  {
    symbol: 'TUPRS',
    name: 'Tüpraş',
    sector: 'Petrol / Rafineri',
    currentPrice: 162.80,
    previousClose: 160.50,
    dayHigh: 164.20,
    dayLow: 159.90,
    marketCap: '313.7 Mr ₺',
    peRatio: 6.15,
    eps: 26.47,
    changePercent: 1.43,
  },
  {
    symbol: 'SISE',
    name: 'Şişecam',
    sector: 'Cam & Seramik',
    currentPrice: 46.30,
    previousClose: 45.80,
    dayHigh: 46.90,
    dayLow: 45.40,
    marketCap: '141.8 Mr ₺',
    peRatio: 8.90,
    eps: 5.20,
    changePercent: 1.09,
  },
  {
    symbol: 'KCHOL',
    name: 'Koç Holding',
    sector: 'Holding & Yatırım',
    currentPrice: 198.40,
    previousClose: 195.00,
    dayHigh: 200.50,
    dayLow: 194.50,
    marketCap: '503.1 Mr ₺',
    peRatio: 5.80,
    eps: 34.20,
    changePercent: 1.74,
  },
  {
    symbol: 'GARAN',
    name: 'Garanti BBVA',
    sector: 'Bankacılık',
    currentPrice: 114.60,
    previousClose: 112.90,
    dayHigh: 116.00,
    dayLow: 112.50,
    marketCap: '481.3 Mr ₺',
    peRatio: 4.60,
    eps: 24.91,
    changePercent: 1.51,
  },
  {
    symbol: 'AKBNK',
    name: 'Akbank',
    sector: 'Bankacılık',
    currentPrice: 58.40,
    previousClose: 57.80,
    dayHigh: 59.10,
    dayLow: 57.50,
    marketCap: '303.6 Mr ₺',
    peRatio: 4.10,
    eps: 14.24,
    changePercent: 1.04,
  },
  {
    symbol: 'YKBNK',
    name: 'Yapı Kredi',
    sector: 'Bankacılık',
    currentPrice: 32.50,
    previousClose: 32.10,
    dayHigh: 33.00,
    dayLow: 31.90,
    marketCap: '274.5 Mr ₺',
    peRatio: 3.95,
    eps: 8.22,
    changePercent: 1.25,
  },
  {
    symbol: 'ISCTR',
    name: 'İş Bankası (C)',
    sector: 'Bankacılık',
    currentPrice: 14.20,
    previousClose: 14.05,
    dayHigh: 14.40,
    dayLow: 13.95,
    marketCap: '355.0 Mr ₺',
    peRatio: 4.30,
    eps: 3.30,
    changePercent: 1.07,
  },
  {
    symbol: 'BIMAS',
    name: 'BİM Mağazalar',
    sector: 'Perakende Ticaret',
    currentPrice: 520.00,
    previousClose: 512.00,
    dayHigh: 524.50,
    dayLow: 510.00,
    marketCap: '315.7 Mr ₺',
    peRatio: 16.40,
    eps: 31.70,
    changePercent: 1.56,
  },
  {
    symbol: 'SASA',
    name: 'Sasa Polyester',
    sector: 'Kimya & Plastik',
    currentPrice: 4.35,
    previousClose: 4.42,
    dayHigh: 4.48,
    dayLow: 4.30,
    marketCap: '187.0 Mr ₺',
    peRatio: 18.20,
    eps: 0.24,
    changePercent: -1.58,
  },
  {
    symbol: 'HEKTS',
    name: 'Hektaş',
    sector: 'Kimya & Tarım',
    currentPrice: 3.82,
    previousClose: 3.90,
    dayHigh: 3.95,
    dayLow: 3.78,
    marketCap: '32.8 Mr ₺',
    peRatio: 22.10,
    eps: 0.17,
    changePercent: -2.05,
  },
  {
    symbol: 'PETKM',
    name: 'Petkim',
    sector: 'Petrokimya',
    currentPrice: 21.40,
    previousClose: 21.15,
    dayHigh: 21.80,
    dayLow: 20.90,
    marketCap: '54.2 Mr ₺',
    peRatio: 11.40,
    eps: 1.87,
    changePercent: 1.18,
  },
  {
    symbol: 'KOZAL',
    name: 'Koza Altın',
    sector: 'Madencilik',
    currentPrice: 22.80,
    previousClose: 22.50,
    dayHigh: 23.20,
    dayLow: 22.30,
    marketCap: '72.9 Mr ₺',
    peRatio: 15.60,
    eps: 1.46,
    changePercent: 1.33,
  },
  {
    symbol: 'FROTO',
    name: 'Ford Otosan',
    sector: 'Otomotiv',
    currentPrice: 1045.00,
    previousClose: 1032.00,
    dayHigh: 1058.00,
    dayLow: 1025.00,
    marketCap: '366.7 Mr ₺',
    peRatio: 8.40,
    eps: 124.40,
    changePercent: 1.26,
  },
  {
    symbol: 'TOASO',
    name: 'Tofaş Oto. Fab.',
    sector: 'Otomotiv',
    currentPrice: 234.00,
    previousClose: 231.50,
    dayHigh: 237.00,
    dayLow: 229.00,
    marketCap: '117.0 Mr ₺',
    peRatio: 7.80,
    eps: 30.00,
    changePercent: 1.08,
  },
  {
    symbol: 'ENKAI',
    name: 'Enka İnşaat',
    sector: 'İnşaat & Taahhüt',
    currentPrice: 47.60,
    previousClose: 46.90,
    dayHigh: 48.20,
    dayLow: 46.50,
    marketCap: '285.6 Mr ₺',
    peRatio: 9.80,
    eps: 4.85,
    changePercent: 1.49,
  },
  {
    symbol: 'MGROS',
    name: 'Migros Ticaret',
    sector: 'Perakende Ticaret',
    currentPrice: 512.00,
    previousClose: 504.00,
    dayHigh: 518.00,
    dayLow: 501.00,
    marketCap: '92.6 Mr ₺',
    peRatio: 10.50,
    eps: 48.76,
    changePercent: 1.59,
  },
  {
    symbol: 'SAHOL',
    name: 'Sabancı Holding',
    sector: 'Holding & Yatırım',
    currentPrice: 94.25,
    previousClose: 93.10,
    dayHigh: 95.50,
    dayLow: 92.80,
    marketCap: '197.9 Mr ₺',
    peRatio: 5.20,
    eps: 18.12,
    changePercent: 1.24,
  },
];

export const FX_ASSETS: FxAsset[] = [
  // Currencies
  {
    id: 'USD/TRY',
    name: 'Amerikan Doları / Türk Lirası',
    symbol: 'USD/TRY',
    currentPrice: 36.42,
    changePercent: 0.18,
    dayHigh: 36.48,
    dayLow: 36.35,
    type: 'currency',
  },
  {
    id: 'EUR/TRY',
    name: 'Euro / Türk Lirası',
    symbol: 'EUR/TRY',
    currentPrice: 38.15,
    changePercent: 0.24,
    dayHigh: 38.28,
    dayLow: 38.02,
    type: 'currency',
  },
  {
    id: 'GBP/TRY',
    name: 'İngiliz Sterlini / Türk Lirası',
    symbol: 'GBP/TRY',
    currentPrice: 45.80,
    changePercent: 0.32,
    dayHigh: 45.98,
    dayLow: 45.62,
    type: 'currency',
  },
  {
    id: 'CHF/TRY',
    name: 'İsviçre Frangı / Türk Lirası',
    symbol: 'CHF/TRY',
    currentPrice: 40.50,
    changePercent: 0.12,
    dayHigh: 40.68,
    dayLow: 40.35,
    type: 'currency',
  },
  {
    id: 'JPY/TRY',
    name: 'Japon Yeni (100) / Türk Lirası',
    symbol: 'JPY/TRY',
    currentPrice: 24.15,
    changePercent: -0.45,
    dayHigh: 24.32,
    dayLow: 24.05,
    type: 'currency',
  },
  {
    id: 'EUR/USD',
    name: 'Euro / Amerikan Doları',
    symbol: 'EUR/USD',
    currentPrice: 1.0475,
    changePercent: 0.08,
    dayHigh: 1.0510,
    dayLow: 1.0450,
    type: 'currency',
  },
  {
    id: 'GBP/USD',
    name: 'İngiliz Sterlini / Amerikan Doları',
    symbol: 'GBP/USD',
    currentPrice: 1.2580,
    changePercent: 0.15,
    dayHigh: 1.2610,
    dayLow: 1.2540,
    type: 'currency',
  },
  // Commodities
  {
    id: 'ALTIN_GR',
    name: 'Gram Altın (TL)',
    symbol: 'Gram Altın',
    currentPrice: 3340.50,
    changePercent: 0.45,
    dayHigh: 3355.00,
    dayLow: 3325.00,
    type: 'commodity',
  },
  {
    id: 'ALTIN_ONS',
    name: 'Ons Altın (USD)',
    symbol: 'XAU/USD',
    currentPrice: 2855.20,
    changePercent: 0.38,
    dayHigh: 2868.00,
    dayLow: 2840.00,
    type: 'commodity',
  },
  {
    id: 'GUMUS_GR',
    name: 'Gram Gümüş (TL)',
    symbol: 'Gram Gümüş',
    currentPrice: 38.80,
    changePercent: 0.72,
    dayHigh: 39.10,
    dayLow: 38.40,
    type: 'commodity',
  },
  {
    id: 'BRENT',
    name: 'Brent Petrol (Varil/USD)',
    symbol: 'BRENT',
    currentPrice: 74.20,
    changePercent: -0.65,
    dayHigh: 75.10,
    dayLow: 73.80,
    type: 'commodity',
  },
  // Crypto
  {
    id: 'BTC/USD',
    name: 'Bitcoin',
    symbol: 'BTC/USD',
    currentPrice: 94800.00,
    changePercent: 1.85,
    dayHigh: 95400.00,
    dayLow: 93200.00,
    type: 'crypto',
  },
  {
    id: 'ETH/USD',
    name: 'Ethereum',
    symbol: 'ETH/USD',
    currentPrice: 2680.50,
    changePercent: 2.10,
    dayHigh: 2720.00,
    dayLow: 2620.00,
    type: 'crypto',
  },
  {
    id: 'SOL/USD',
    name: 'Solana',
    symbol: 'SOL/USD',
    currentPrice: 178.40,
    changePercent: 3.45,
    dayHigh: 182.00,
    dayLow: 172.50,
    type: 'crypto',
  },
  {
    id: 'AVAX/USD',
    name: 'Avalanche',
    symbol: 'AVAX/USD',
    currentPrice: 28.60,
    changePercent: 1.20,
    dayHigh: 29.40,
    dayLow: 28.10,
    type: 'crypto',
  },
];

// Helper to construct stock query URIs based on user configuration
export const StockRequestBuilder = {
  buildSymbol(rawSymbol: string, appendDotIs: boolean): string {
    const clean = rawSymbol.trim().toUpperCase().replace(/\.IS$/, '');
    return appendDotIs ? `${clean}.IS` : clean;
  },

  buildUri(apiUrl: string, apiKey: string, rawSymbol: string, appendDotIs: boolean): string {
    const symbol = this.buildSymbol(rawSymbol, appendDotIs);
    let url = apiUrl.trim();

    if (url.includes('{symbol}') || url.includes('{apiKey}')) {
      return url
        .replace('{symbol}', encodeURIComponent(symbol))
        .replace('{apiKey}', encodeURIComponent(apiKey));
    }

    try {
      const parsed = new URL(url.startsWith('http') ? url : `https://${url}`);
      parsed.searchParams.set('symbol', symbol);
      parsed.searchParams.set('apikey', apiKey);
      return parsed.toString();
    } catch {
      const sep = url.includes('?') ? '&' : '?';
      return `${url}${sep}symbol=${encodeURIComponent(symbol)}&apikey=${encodeURIComponent(apiKey)}`;
    }
  },
};

export interface ProxyResponse {
  ok: boolean;
  status: number;
  statusText: string;
  json: () => Promise<any>;
  text: () => Promise<string>;
}

export async function proxyFetch(
  targetUrl: string,
  options: { method?: string; headers?: Record<string, string>; body?: any } = {}
): Promise<ProxyResponse> {
  const method = (options.method || 'GET').toUpperCase();
  const headers = options.headers || {};
  const cleanApiKey = headers['X-API-Key'] || headers['x-api-key'] || headers['apikey'] || '';

  // Tier 1: App internal /api/proxy endpoint
  try {
    const queryParams = new URLSearchParams({
      url: targetUrl,
      ...(cleanApiKey ? { apiKey: cleanApiKey } : {}),
      method,
    });

    const isGet = method === 'GET' || method === 'HEAD';
    const requestHeaders: Record<string, string> = {
      'Accept': 'application/json, text/plain, */*',
      ...(cleanApiKey ? { 'X-API-Key': cleanApiKey } : {}),
      ...headers,
    };

    if (!isGet) {
      requestHeaders['Content-Type'] = 'application/json';
    }

    const proxyRes = await fetch(`/api/proxy?${queryParams.toString()}`, {
      method: isGet ? 'GET' : 'POST',
      headers: requestHeaders,
      body: !isGet && options.body ? (typeof options.body === 'string' ? options.body : JSON.stringify(options.body)) : undefined,
    });

    // If server responded with any valid HTTP status
    const contentType = proxyRes.headers.get('content-type') || '';
    let parsedJson: any = null;
    let rawText = '';

    try {
      if (contentType.includes('application/json')) {
        parsedJson = await proxyRes.json();
      } else {
        rawText = await proxyRes.text();
      }
    } catch {
      // ignore parse fail
    }

    // Return the proxy response directly
    return {
      ok: proxyRes.ok,
      status: proxyRes.status,
      statusText: proxyRes.statusText,
      json: async () => parsedJson || (rawText ? JSON.parse(rawText) : {}),
      text: async () => rawText || (parsedJson ? JSON.stringify(parsedJson) : ''),
    };
  } catch (proxyErr: any) {
    console.warn('Local /api/proxy endpoint failed, trying CORS proxy fallback...', proxyErr);
  }

  // Tier 2: Public high-speed CORS Proxy (corsproxy.io)
  try {
    const proxyUrl = `https://corsproxy.io/?${encodeURIComponent(targetUrl)}`;
    const res = await fetch(proxyUrl, {
      method,
      headers: {
        ...headers,
        'Accept': 'application/json, text/plain, */*',
      },
      body: method !== 'GET' && method !== 'HEAD' && options.body ? JSON.stringify(options.body) : undefined,
    });
    return {
      ok: res.ok,
      status: res.status,
      statusText: res.statusText,
      json: () => res.json(),
      text: () => res.text(),
    };
  } catch (err2) {
    console.warn('corsproxy.io fallback failed, trying next fallback...', err2);
  }

  // Tier 3: Public CORS Proxy (allorigins.win)
  try {
    const proxyUrl = `https://api.allorigins.win/raw?url=${encodeURIComponent(targetUrl)}`;
    const res = await fetch(proxyUrl, {
      method,
      headers: {
        ...headers,
        'Accept': 'application/json, text/plain, */*',
      },
    });
    if (res.ok) {
      return {
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => res.json(),
        text: () => res.text(),
      };
    }
  } catch (err3) {
    console.warn('allorigins fallback failed, trying direct fetch...', err3);
  }

  // Tier 4: Direct browser fetch
  try {
    const directRes = await fetch(targetUrl, {
      method,
      headers,
      body: method !== 'GET' && method !== 'HEAD' && options.body ? JSON.stringify(options.body) : undefined,
    });
    return {
      ok: directRes.ok,
      status: directRes.status,
      statusText: directRes.statusText,
      json: () => directRes.json(),
      text: () => directRes.text(),
    };
  } catch (directErr: any) {
    return {
      ok: false,
      status: 0,
      statusText: directErr?.message || 'Tarayıcı ağ engeli',
      json: async () => ({ error: directErr?.message || 'Ağ hatası' }),
      text: async () => directErr?.message || 'Ağ hatası',
    };
  }
}

// Automatically resolve full API URL for funds based on user configuration
export function resolveFundEndpoint(providerUrl: string | undefined, code: string, subpath: string = ''): string {
  let provider = (providerUrl || '').trim();
  if (!provider || provider.toLowerCase() === 'fonoloji' || provider.toLowerCase() === 'default') {
    provider = 'https://fonoloji.com';
  }
  provider = provider.replace(/\/+$/, '');

  const normalizedCode = code.toUpperCase().trim();
  const sub = subpath ? `/${subpath.replace(/^\/+/, '')}` : '';

  if (provider.includes('/v1/funds')) {
    return `${provider}/${normalizedCode}${sub}`;
  }
  if (provider.includes('/funds')) {
    return `${provider}/${normalizedCode}${sub}`;
  }
  if (provider.startsWith('http://') || provider.startsWith('https://')) {
    return `${provider}/v1/funds/${normalizedCode}${sub}`;
  }
  return `https://fonoloji.com/v1/funds/${normalizedCode}${sub}`;
}

export const MarketDataService = {
  // Test connection to Fund API
  async testFundConnection(providerName: string, apiKey: string): Promise<string> {
    const cleanKey = apiKey.trim().replace(/^["']|["']$/g, '');
    if (!cleanKey) return 'Bu veri kaynağı için API bilgisi tanımlanmamış. Lütfen API anahtarınızı giriniz.';
    try {
      const url = resolveFundEndpoint(providerName, 'KLU');
      const res = await proxyFetch(url, {
        headers: { 
          'X-API-Key': cleanKey,
          'Accept': 'application/json',
        },
      });

      let json: any = null;
      let errorMsg = '';
      try {
        json = await res.json();
        errorMsg = json?.error || json?.message || json?.detail || '';
      } catch {
        // ignore parse error
      }

      if (res.ok) {
        const fundData = json?.fund || json;
        const price = fundData?.current_price ?? fundData?.price ?? fundData?.last_price;
        const priceStr = price ? ` - KLU Fiyatı: ${Number(price).toFixed(4)} ₺` : '';
        return `✅ Bağlantı başarılı! Fonoloji API aktif${priceStr}`;
      }

      if (res.status === 401 || res.status === 403) {
        return `❌ API anahtarı geçersiz veya yetkisiz (HTTP ${res.status}): ${errorMsg || 'Geçersiz veya iptal edilmiş API anahtarı.'}`;
      }
      if (res.status === 429) {
        return `❌ Kota limiti aşılmış (HTTP 429): ${errorMsg || 'Çok fazla istek yapıldı.'}`;
      }
      if (res.status === 404) {
        return `❌ Fon uç noktası bulunamadı (HTTP 404). Lütfen API URL adresini kontrol edin. (${url})`;
      }
      if (errorMsg) {
        return `❌ API Hatası (${res.status}): ${errorMsg}`;
      }
      return `❌ Servis yanıt vermedi (${res.status || 'Hata'})`;
    } catch (err: any) {
      return `❌ Servise ulaşılamadı: ${err.message || 'Ağ hatası'}`;
    }
  },

  // Test connection to Stock API
  async testStockConnection(apiUrl: string, apiKey: string, appendDotIs: boolean): Promise<string> {
    if (!apiKey.trim() || !apiUrl.trim()) return 'Bu veri kaynağı için API bilgisi tanımlanmamış. Bilgileri giriniz.';
    try {
      const uri = StockRequestBuilder.buildUri(apiUrl, apiKey, 'THYAO', appendDotIs);
      const res = await proxyFetch(uri);
      if (res.ok) {
        const data = await res.json();
        if (data.status === 'error' || data.code === 400 || data.code === 401 || data.code === 404) {
          return `❌ API anahtarı geçersiz: ${data.message || data.error?.message || 'Yetkilendirme hatası'}`;
        }
        if (data.error) {
          return `❌ Hata: ${data.error.message || data.error.info || 'API hata döndürdü'}`;
        }
        return '✅ Bağlantı başarılı';
      }

      if (res.status === 401 || res.status === 403) {
        return '❌ API anahtarı geçersiz';
      }
      if (res.status === 429) {
        return '❌ Kota limiti aşılmış olabilir';
      }
      return `❌ Servise ulaşılamadı (${res.status || 'Hata'})`;
    } catch (err: any) {
      return `❌ Servise ulaşılamadı: ${err.message || 'Ağ hatası'}`;
    }
  },

  // Test connection to FX API
  async testFxConnection(providerName: string, apiKey: string): Promise<string> {
    if (!apiKey.trim()) return 'Bu veri kaynağı için API bilgisi tanımlanmamış. Bilgileri giriniz.';
    try {
      const baseUrl = providerName.trim().startsWith('http')
        ? (providerName.endsWith('/') ? providerName : `${providerName}/`)
        : 'https://v6.exchangerate-api.com/v6/';
      const url = `${baseUrl}${apiKey.trim()}/latest/USD`;
      const res = await proxyFetch(url);
      if (res.ok) {
        const data = await res.json();
        if (data.result === 'success') return '✅ Bağlantı başarılı';
        return `❌ Hata: ${data['error-type'] || 'API hata döndürdü'}`;
      }
      if (res.status === 401 || res.status === 403) {
        return '❌ API anahtarı geçersiz';
      }
      if (res.status === 429) {
        return '❌ Kota limiti aşılmış olabilir';
      }
      return `❌ Servise ulaşılamadı (${res.status || 'Hata'})`;
    } catch (err: any) {
      return `❌ Servise ulaşılamadı: ${err.message || 'Ağ hatası'}`;
    }
  },

  // Get Fund detail
  async getFundDetail(code: string): Promise<Fund> {
    const normalized = code.toUpperCase().trim();
    const settings = StorageService.getSettings();

    // If Fonoloji API key provided, attempt real API via server-side proxy
    if (settings.fonolojiApiKey) {
      try {
        const url = resolveFundEndpoint(settings.fundProvider, normalized);
        const res = await proxyFetch(url, {
          headers: { 'X-API-Key': settings.fonolojiApiKey.trim() },
        });
        if (res.ok) {
          const json = await res.json();
          const fundData = json.fund || json;
          if (fundData && !json.error) {
            const curPrice = Number(fundData.current_price ?? fundData.price ?? fundData.last_price ?? 0);
            const prevClose = Number(fundData.previous_close ?? fundData.prev_close ?? curPrice);
            return {
              code: normalized,
              name: fundData.name || fundData.title || normalized,
              category: fundData.category || fundData.fund_type || 'Yatırım Fonu',
              currentPrice: curPrice > 0 ? curPrice : (POPULAR_FUNDS[normalized]?.currentPrice || 1),
              previousClose: prevClose > 0 ? prevClose : (POPULAR_FUNDS[normalized]?.previousClose || curPrice),
              return1Y: Number(fundData.return_1y ?? fundData.yearly_return ?? POPULAR_FUNDS[normalized]?.return1Y ?? 0),
              realReturn1Y: Number(fundData.real_return_1y ?? POPULAR_FUNDS[normalized]?.realReturn1Y ?? 0),
              riskScore: Number(fundData.risk_score ?? fundData.risk ?? POPULAR_FUNDS[normalized]?.riskScore ?? 4),
              sharpe90: Number(fundData.sharpe_90 ?? POPULAR_FUNDS[normalized]?.sharpe90 ?? 1.5),
            };
          }
        }
      } catch (err) {
        console.warn('Live fonoloji API request failed, falling back to catalog/local dataset', err);
      }
    }

    // Check comprehensive TEFAS catalog
    const catalogMatch = TEFAS_FUNDS_CATALOG.find((f) => f.code === normalized);
    if (catalogMatch) {
      return {
        code: catalogMatch.code,
        name: catalogMatch.name,
        category: catalogMatch.category,
        currentPrice: catalogMatch.currentPrice,
        previousClose: Number((catalogMatch.currentPrice * 0.996).toFixed(4)),
        return1Y: catalogMatch.return1Y,
        realReturn1Y: catalogMatch.realReturn1Y,
        riskScore: catalogMatch.riskScore,
        sharpe90: catalogMatch.sharpe90,
      };
    }

    // Curated dataset match
    const found = POPULAR_FUNDS[normalized];
    if (found) {
      return {
        code: normalized,
        ...found,
      };
    }

    // Dynamic procedural fund mock if code is valid 3 or 4 letters
    const hash = normalized.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const mockPrice = 1.0 + (hash % 100) * 0.08;
    const mock1Y = 45 + (hash % 60);
    const mockRisk = 1 + (hash % 7);
    return {
      code: normalized,
      name: `${normalized} Portföy Değişken Yatırım Fonu`,
      category: 'Değişken Şemsiye Fonu',
      currentPrice: Number(mockPrice.toFixed(4)),
      previousClose: Number((mockPrice * 0.992).toFixed(4)),
      return1Y: mock1Y,
      realReturn1Y: Math.max(0, mock1Y - 48),
      riskScore: mockRisk,
      sharpe90: Number((1.2 + (hash % 15) * 0.1).toFixed(2)),
    };
  },

  // Generate or fetch fund history
  async getFundHistory(code: string, currentPrice: number): Promise<HistoryPoint[]> {
    const normalized = code.toUpperCase().trim();
    const settings = StorageService.getSettings();

    // If Fonoloji API key provided, attempt real history API
    if (settings.fonolojiApiKey) {
      try {
        const url = resolveFundEndpoint(settings.fundProvider, normalized, 'history');
        const res = await proxyFetch(url, {
          headers: { 'X-API-Key': settings.fonolojiApiKey.trim() },
        });
        if (res.ok) {
          const json = await res.json();
          const pointsList = (json.points || json.history || json) as any[];
          if (Array.isArray(pointsList) && pointsList.length > 0) {
            const points: HistoryPoint[] = pointsList
              .map((item: any) => ({
                date: item.date || item.t || item.time,
                price: Number(item.price || item.p || item.value || 0),
              }))
              .filter((p) => p.date && p.price > 0);

            points.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
            const oneYearAgo = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
            const filtered = points.filter((p) => new Date(p.date) >= oneYearAgo);
            if (filtered.length > 0) {
              return filtered;
            }
          }
        }
      } catch (err) {
        console.warn('Live history API request failed, using procedural points', err);
      }
    }

    const points: HistoryPoint[] = [];
    const now = new Date();
    const days = 365;
    
    // Seeded random walk based on fund code
    const hash = normalized.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const startPrice = currentPrice / (1 + 0.70); // roughly 70% 1Y return base
    
    let runningPrice = startPrice;
    for (let i = days; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      // Skip weekends
      if (d.getDay() === 0 || d.getDay() === 6) continue;
      
      const dayIndex = days - i;
      const noise = (Math.sin((dayIndex + hash) * 0.15) * 0.008) + ((Math.random() - 0.47) * 0.012);
      const upwardDrift = (currentPrice - startPrice) / days;
      runningPrice = Math.max(0.01, runningPrice + upwardDrift + (runningPrice * noise));
      
      // Pin the final day to the exact current price
      if (i === 0) {
        runningPrice = currentPrice;
      }

      points.push({
        date: d.toISOString().split('T')[0],
        price: Number(runningPrice.toFixed(4)),
      });
    }

    return points;
  },

  // Search funds across all TEFAS funds catalog & popular funds
  searchFunds(query: string): { code: string; name: string; currentPrice: number; return1Y: number; category?: string }[] {
    const raw = query.trim();
    const normalizeTr = (str: string) =>
      str
        .toLocaleUpperCase('tr-TR')
        .replace(/İ/g, 'I')
        .replace(/Ş/g, 'S')
        .replace(/Ğ/g, 'G')
        .replace(/Ü/g, 'U')
        .replace(/Ö/g, 'O')
        .replace(/Ç/g, 'C')
        .trim();

    const normalized = normalizeTr(raw);

    // Merge catalog & popular funds without duplicates
    const allFundsMap = new Map<string, { code: string; name: string; currentPrice: number; return1Y: number; category?: string; managementCompany?: string }>();

    // Add all catalog funds
    for (const f of TEFAS_FUNDS_CATALOG) {
      allFundsMap.set(f.code, {
        code: f.code,
        name: f.name,
        currentPrice: f.currentPrice,
        return1Y: f.return1Y,
        category: f.category,
        managementCompany: f.managementCompany,
      });
    }

    // Add popular funds
    for (const [code, data] of Object.entries(POPULAR_FUNDS)) {
      if (!allFundsMap.has(code)) {
        allFundsMap.set(code, {
          code,
          name: data.name,
          currentPrice: data.currentPrice,
          return1Y: data.return1Y,
          category: data.category,
        });
      }
    }

    const allFundsList = Array.from(allFundsMap.values());

    if (!normalized) {
      return allFundsList;
    }

    const matches = allFundsList.filter((f) => {
      const normCode = normalizeTr(f.code);
      const normName = normalizeTr(f.name);
      const normCat = normalizeTr(f.category || '');
      const normCompany = normalizeTr(f.managementCompany || '');
      return (
        normCode.includes(normalized) ||
        normName.includes(normalized) ||
        normCat.includes(normalized) ||
        normCompany.includes(normalized)
      );
    });

    // If exact 3-4 letter uppercase code is typed and not in catalog, dynamically generate an entry
    const isCodeFormat = /^[A-Z0-9]{3,5}$/i.test(raw);
    const upperRaw = raw.toUpperCase();
    if (isCodeFormat && !matches.some((m) => m.code === upperRaw)) {
      const hash = upperRaw.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
      const mockPrice = Number((1.0 + (hash % 100) * 0.08).toFixed(4));
      const mock1Y = 45 + (hash % 60);
      matches.unshift({
        code: upperRaw,
        name: `${upperRaw} TEFAS Fonu`,
        currentPrice: mockPrice,
        return1Y: mock1Y,
        category: 'Yatırım Fonu',
      });
    }

    return matches;
  },

  // Search stocks
  searchStocks(query: string): Stock[] {
    const normalized = query.toUpperCase().trim();
    if (!normalized) return BIST_STOCKS;
    return BIST_STOCKS.filter(
      (s) => s.symbol.includes(normalized) || s.name.toUpperCase().includes(normalized) || s.sector.toUpperCase().includes(normalized)
    );
  },

  // Get Stock Detail
  getStockDetail(symbol: string): Stock {
    const normalized = symbol.toUpperCase().trim();
    const found = BIST_STOCKS.find((s) => s.symbol === normalized);
    if (found) return found;

    // Fallback stock
    return {
      symbol: normalized,
      name: `${normalized} Sanayi ve Ticaret A.Ş.`,
      sector: 'BIST Tüm',
      currentPrice: 42.50,
      previousClose: 41.80,
      dayHigh: 43.20,
      dayLow: 41.50,
      marketCap: '12.5 Mr ₺',
      peRatio: 8.5,
      eps: 5.0,
      changePercent: 1.67,
    };
  },

  // Search FX Assets
  searchFx(query: string): FxAsset[] {
    const normalized = query.toUpperCase().trim();
    if (!normalized) return FX_ASSETS;
    return FX_ASSETS.filter(
      (a) =>
        a.symbol.toUpperCase().includes(normalized) ||
        a.name.toUpperCase().includes(normalized) ||
        a.id.toUpperCase().includes(normalized)
    );
  },

  // Calculate Fund Holdings summary
  calculateFundHoldings(): Holding[] {
    const txs = StorageService.getFundTransactions();
    const map = new Map<string, { totalQty: number; totalCost: number }>();

    // Process transactions in chronological order
    const sorted = [...txs].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    for (const tx of sorted) {
      const code = tx.fundCode.toUpperCase();
      const current = map.get(code) || { totalQty: 0, totalCost: 0 };
      if (tx.type === 'BUY') {
        current.totalQty += tx.quantity;
        current.totalCost += tx.quantity * tx.unitPrice;
      } else if (tx.type === 'SELL') {
        const avgCost = current.totalQty > 0 ? current.totalCost / current.totalQty : 0;
        current.totalQty = Math.max(0, current.totalQty - tx.quantity);
        current.totalCost = Math.max(0, current.totalQty * avgCost);
      }
      map.set(code, current);
    }

    const holdings: Holding[] = [];
    let totalPortfolioValue = 0;

    for (const [code, { totalQty, totalCost }] of map.entries()) {
      if (totalQty <= 0) continue;
      const fundInfo = POPULAR_FUNDS[code] || {
        name: `${code} Fonu`,
        currentPrice: totalCost / totalQty,
        previousClose: (totalCost / totalQty) * 0.995,
      };
      const currentPrice = fundInfo.currentPrice;
      const currentValue = totalQty * currentPrice;
      const averageCost = totalCost / totalQty;
      const profitLoss = currentValue - totalCost;
      const profitLossPercent = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
      const prevClose = fundInfo.previousClose || currentPrice;
      const dailyChangePercent = prevClose > 0 ? ((currentPrice - prevClose) / prevClose) * 100 : 0;
      const dailyChangeValue = totalQty * (currentPrice - prevClose);

      totalPortfolioValue += currentValue;
      holdings.push({
        fundCode: code,
        name: fundInfo.name,
        quantity: totalQty,
        averageCost,
        costValue: totalCost,
        currentPrice,
        currentValue,
        profitLoss,
        profitLossPercent,
        dailyChangePercent,
        dailyChangeValue,
        portfolioSharePercent: 0, // Calculated below
      });
    }

    // Calculate portfolio shares
    if (totalPortfolioValue > 0) {
      for (const h of holdings) {
        h.portfolioSharePercent = (h.currentValue / totalPortfolioValue) * 100;
      }
    }

    return holdings.sort((a, b) => b.currentValue - a.currentValue);
  },

  // Calculate Stock Holdings summary
  calculateStockHoldings(): StockHolding[] {
    const txs = StorageService.getStockTransactions();
    const map = new Map<string, { totalQty: number; totalCost: number }>();

    const sorted = [...txs].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    for (const tx of sorted) {
      const symbol = tx.stockSymbol.toUpperCase();
      const current = map.get(symbol) || { totalQty: 0, totalCost: 0 };
      if (tx.type === 'BUY') {
        current.totalQty += tx.quantity;
        current.totalCost += tx.quantity * tx.unitPrice;
      } else if (tx.type === 'SELL') {
        const avgCost = current.totalQty > 0 ? current.totalCost / current.totalQty : 0;
        current.totalQty = Math.max(0, current.totalQty - tx.quantity);
        current.totalCost = Math.max(0, current.totalQty * avgCost);
      }
      map.set(symbol, current);
    }

    const holdings: StockHolding[] = [];
    let totalPortfolioValue = 0;

    for (const [symbol, { totalQty, totalCost }] of map.entries()) {
      if (totalQty <= 0) continue;
      const stockInfo = BIST_STOCKS.find((s) => s.symbol === symbol) || {
        name: `${symbol} Payı`,
        currentPrice: totalCost / totalQty,
        previousClose: (totalCost / totalQty) * 0.99,
        changePercent: 1.0,
      };
      const currentPrice = stockInfo.currentPrice;
      const currentValue = totalQty * currentPrice;
      const averageCost = totalCost / totalQty;
      const profitLoss = currentValue - totalCost;
      const profitLossPercent = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
      const prevClose = stockInfo.previousClose || currentPrice;
      const dailyChangePercent = prevClose > 0 ? ((currentPrice - prevClose) / prevClose) * 100 : 0;
      const dailyChangeValue = totalQty * (currentPrice - prevClose);

      totalPortfolioValue += currentValue;
      holdings.push({
        stockSymbol: symbol,
        name: stockInfo.name,
        quantity: totalQty,
        averageCost,
        costValue: totalCost,
        currentPrice,
        currentValue,
        profitLoss,
        profitLossPercent,
        dailyChangePercent,
        dailyChangeValue,
        portfolioSharePercent: 0,
      });
    }

    if (totalPortfolioValue > 0) {
      for (const h of holdings) {
        h.portfolioSharePercent = (h.currentValue / totalPortfolioValue) * 100;
      }
    }

    return holdings.sort((a, b) => b.currentValue - a.currentValue);
  },
};
