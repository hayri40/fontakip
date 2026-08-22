import express from 'express';
import type { Request, Response } from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { GoogleGenAI } from '@google/genai';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Initialize Google GenAI client (using recommended gemini-3.7-flash)
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
  httpOptions: {
    headers: {
      'User-Agent': 'aistudio-build',
    },
  },
});

// FX Expert AI Chat & Analysis Endpoint
app.post('/api/expert/chat', async (req: Request, res: Response) => {
  try {
    const { message, currentRules = [], history = [], symbol = 'GBPCAD', timeframe = '1H' } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'Mesaj metni zorunludur.' });
    }

    const rulesContext = Array.isArray(currentRules) && currentRules.length > 0
      ? `MEVCUT ÖĞRENİLMİŞ UZMAN KURALLARI (${currentRules.length} kural aktif):\n` +
        currentRules
          .map((r: any, idx: number) => `${idx + 1}. [${r.category || 'Genel'}] ${r.title}: ${r.rule}`)
          .join('\n')
      : 'Henüz özel kural tanımlanmamış, standart profesyonel kurallar geçerlidir.';

    const systemInstruction = `
Sen kullanıcı için çalışan tek, kıdemli ve disiplinli bir **FX Baş Stratejisti & Teknik Analiz Danışmanısın**.
Kullanıcı seninle Türkçe konuşur. Sen de profesyonel, samimi, disiplinli ve piyasa gerçeklerine uygun bir dille yanıt verirsin.

TEMEL PRENSİPLERİN VE GÖREVLERİN:
1. **Piyasa Analizi ve İşlem Kurulumları**:
   - Kullanıcı senden analiz, destek-direnç, trend kanalı, işleme giriş, TP (Kâr Al), SL (Zarar Durdur) seviyeleri istediğinde veya genel teknik durumu sorduğunda (Örn: ${symbol} ${timeframe}):
   - Fiyat seviyelerini gerçekçi, orantılı ve net belirle.
   - Stop Loss (SL) ve Take Profit (TP1, TP2) seviyelerini kesinlikle Risk/Ödül oranı minimum 1:2 olacak şekilde hesapla.
   - Destek ve Direnç bölgelerini ("zones") ve trend kanalını ("channel") yapay zeka çıktısının "analysisSetup" alanına ekle.

2. **Kural Öğrenme ve Hafızaya Kaydetme (Çok Önemli)**:
   - Kullanıcıyla sohbet ederken, kullanıcının belirttiği veya birlikte kararlaştırdığınız strateji, risk yönetimi, işlem açma saatleri, seans tercihleri, parite kuralları, lot disiplini gibi İLKELERİ/KURALLARI tespit et.
   - Yeni bir kural veya ilke çıktığında bunu 'newRules' listesinde yapılandırılmış olarak döndür. Bu kurallar kullanıcının "Uzman Kuralları" paneline otomatik kaydedilecektir.

3. **Mevcut Kurallara Bağlılık**:
   ${rulesContext}
   - Analiz ve öneri sunarken kullanıcının bu mevcut kurallarına titizlikle sadık kal!

ÇIKTI FORMATI:
SADECE GEÇERLİ JSON FORMATINDA CEVAP VER. Şema:
{
  "message": "Kullanıcıya Türkçe açıklayıcı, profesyonel uzman analizi ve değerlendirmesi (Markdown formatında, maddeler halinde)",
  "analysisSetup": {
    "pair": "${symbol}",
    "timeframe": "${timeframe}",
    "action": "BUY" | "SELL" | "BEKLE",
    "entryPrice": 1.74520,
    "stopLoss": 1.74100,
    "takeProfit1": 1.75360,
    "takeProfit2": 1.75900,
    "riskRewardRatio": "1:2.0",
    "zones": [
      { "label": "Önemli Talep Bölgesi / Destek", "type": "support", "price": 1.74200, "strength": "high" },
      { "label": "Likidite / Arz Bölgesi (Direnç)", "type": "resistance", "price": 1.75500, "strength": "medium" }
    ],
    "channel": {
      "trend": "Yükseliş (Bullish)" | "Düşüş (Bearish)" | "Yatay (Range)",
      "upperLine": 1.75800,
      "lowerLine": 1.74150
    },
    "rationale": "Teknik kurulum gerekçesi ve risk yönetimi uyarısı"
  },
  "newRules": [
    {
      "title": "Kural Başlığı",
      "rule": "Öğrenilen kuralın net ve uygulanabilir metni",
      "category": "Risk Yönetimi" | "Giriş ve Çıkış Stratejisi" | "Parite & Volatilite" | "Zaman Dilimi & Seanslar" | "Psikoloji & Disiplin" | "Genel Kural",
      "sourceContext": "Kullanıcı sohbetinden öğrenildi"
    }
  ]
}
Not: "analysisSetup" sadece teknik analiz/seviye çizimi gerektiğinde dolu olmalıdır; genel sohbette null olabilir. "newRules" sadece yeni kural/prensip konuşulduğunda dolu olmalıdır; aksi halde boş dizi [] veya null olmalıdır.
`;

    // Format chat history
    let contents = '';
    if (Array.isArray(history) && history.length > 0) {
      const recentHistory = history.slice(-6);
      contents += 'Önceki Konuşma Geçmişi:\n';
      recentHistory.forEach((h: any) => {
        contents += `${h.sender === 'user' ? 'Kullanıcı' : 'Uzman'}: ${h.text}\n`;
      });
      contents += '\nŞimdiki Kullanıcı Mesajı:\n' + message;
    } else {
      contents = message;
    }

    const aiResponse = await ai.models.generateContent({
      model: 'gemini-3.7-flash',
      contents: contents,
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
      },
    });

    const responseText = aiResponse.text || '{}';
    let parsedData: any = {};
    try {
      parsedData = JSON.parse(responseText);
    } catch {
      parsedData = {
        message: responseText,
      };
    }

    return res.json({
      message: parsedData.message || responseText,
      analysisSetup: parsedData.analysisSetup || null,
      newRules: Array.isArray(parsedData.newRules) ? parsedData.newRules : [],
    });
  } catch (err: any) {
    console.error('Expert AI Chat Error:', err);
    return res.status(500).json({
      error: 'Uzman analist şu anda yanıt veremedi: ' + (err.message || 'Bilinmeyen hata'),
    });
  }
});


// Market data proxy to bypass browser CORS for external APIs (Fonoloji, TwelveData, MarketStack, ExchangeRate, etc.)
app.all('/api/proxy', async (req: Request, res: Response) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key, x-api-key, x-api-token, apikey, *');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  try {
    const targetUrl = (req.method === 'GET' ? req.query.url : (req.body?.url || req.query.url)) as string;
    const queryApiKey = (req.query.apiKey || req.query.apikey || req.query['x-api-key']) as string;

    if (!targetUrl) {
      return res.status(400).json({ error: 'Missing target url parameter' });
    }

    const headers: Record<string, string> = {};

    if (req.headers['accept']) {
      headers['Accept'] = String(req.headers['accept']);
    } else {
      headers['Accept'] = 'application/json, text/plain, */*';
    }

    // Priority for API Key
    const apiKey = queryApiKey || 
      req.headers['x-api-key'] || 
      req.headers['X-API-Key'] || 
      req.headers['apikey'] || 
      req.body?.apiKey ||
      (req.body?.headers && (req.body.headers['X-API-Key'] || req.body.headers['x-api-key'] || req.body.headers['apikey']));

    if (apiKey) {
      headers['X-API-Key'] = String(apiKey).trim();
    }

    headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

    const method = (req.method === 'GET' ? ((req.query.method as string) || 'GET') : (req.body?.method || 'GET')).toUpperCase();
    
    const fetchOptions: RequestInit = {
      method,
      headers,
    };

    if (method !== 'GET' && method !== 'HEAD' && req.body?.body) {
      fetchOptions.body = typeof req.body.body === 'string' ? req.body.body : JSON.stringify(req.body.body);
    }

    // Upstream fetch with 8s abort timeout
    const controller = new AbortController();
    const fetchTimer = setTimeout(() => controller.abort(), 8000);
    fetchOptions.signal = controller.signal;

    try {
      const upstreamRes = await fetch(targetUrl, fetchOptions);
      clearTimeout(fetchTimer);

      const contentType = upstreamRes.headers.get('content-type') || '';
      res.status(upstreamRes.status);
      
      if (contentType.includes('application/json')) {
        const data = await upstreamRes.json();
        return res.json(data);
      } else {
        const text = await upstreamRes.text();
        res.setHeader('Content-Type', contentType || 'text/plain');
        return res.send(text);
      }
    } catch (fetchErr: any) {
      clearTimeout(fetchTimer);
      return res.status(502).json({ 
        error: 'Upstream servise ulaşılamadı: ' + (fetchErr.name === 'AbortError' ? 'Zaman aşımı (8s)' : (fetchErr.message || 'Bağlantı hatası')),
        url: targetUrl 
      });
    }
  } catch (err: any) {
    console.error('API Proxy Error:', err);
    return res.status(500).json({ error: 'Proxy hatası: ' + (err.message || 'Bilinmeyen hata') });
  }
});

// Serve frontend static assets in production
const distPath = path.join(__dirname, 'dist');
app.use(express.static(distPath));

app.use((req: Request, res: Response) => {
  if (req.path.startsWith('/api')) {
    return res.status(404).json({ error: 'API endpoint not found' });
  }
  res.sendFile(path.join(distPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
