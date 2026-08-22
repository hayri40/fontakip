import React, { useState, useEffect } from 'react';
import {
  Clock,
  Globe2,
  TrendingUp,
  Activity,
  CheckCircle2,
  AlertCircle,
  Calendar,
} from 'lucide-react';

interface MarketSession {
  city: string;
  country: string;
  name: string;
  openUtc: number; // UTC hour
  closeUtc: number;
  openLocal: string;
  closeLocal: string;
  accentColor: string;
}

export const GlobalMarketHours: React.FC = () => {
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const currentUtcHour = now.getUTCHours() + now.getUTCMinutes() / 60;
  const trHour = (now.getUTCHours() + 3) % 24;

  const sessions: MarketSession[] = [
    {
      city: 'Sidney',
      country: 'Avustralya (ASX)',
      name: 'Sidney Seansı',
      openUtc: 22,
      closeUtc: 7,
      openLocal: '01:00 TSİ',
      closeLocal: '10:00 TSİ',
      accentColor: 'from-blue-500 to-cyan-400',
    },
    {
      city: 'Tokyo',
      country: 'Japonya (TSE)',
      name: 'Tokyo Seansı',
      openUtc: 0,
      closeUtc: 9,
      openLocal: '03:00 TSİ',
      closeLocal: '12:00 TSİ',
      accentColor: 'from-red-500 to-amber-400',
    },
    {
      city: 'Londra',
      country: 'İngiltere (LSE)',
      name: 'Londra Seansı',
      openUtc: 8,
      closeUtc: 16.5,
      openLocal: '11:00 TSİ',
      closeLocal: '19:30 TSİ',
      accentColor: 'from-purple-500 to-indigo-400',
    },
    {
      city: 'New York',
      country: 'ABD (NYSE / NASDAQ)',
      name: 'New York Seansı',
      openUtc: 13.5,
      closeUtc: 20,
      openLocal: '16:30 TSİ',
      closeLocal: '23:00 TSİ',
      accentColor: 'from-emerald-500 to-teal-400',
    },
  ];

  const isSessionOpen = (session: MarketSession) => {
    const day = now.getUTCDay();
    // Weekends (Saturday / Sunday)
    if (day === 6 || (day === 0 && currentUtcHour < 22) || (day === 5 && currentUtcHour >= 22)) {
      return false;
    }

    if (session.openUtc > session.closeUtc) {
      // Overnight session (e.g. Sydney 22:00 to 07:00)
      return currentUtcHour >= session.openUtc || currentUtcHour < session.closeUtc;
    }
    return currentUtcHour >= session.openUtc && currentUtcHour < session.closeUtc;
  };

  const getActiveSessionsCount = () => {
    return sessions.filter((s) => isSessionOpen(s)).length;
  };

  const getVolatilityRating = () => {
    const isLondonOpen = isSessionOpen(sessions[2]);
    const isNyOpen = isSessionOpen(sessions[3]);
    const isTokyoOpen = isSessionOpen(sessions[1]);
    const isSydneyOpen = isSessionOpen(sessions[0]);

    if (isLondonOpen && isNyOpen) {
      return {
        level: 'ÇOK YÜKSEK VOLATİLİTE',
        badge: 'bg-red-500/20 text-red-400 border-red-500/40',
        desc: 'Londra ve New York seansları çakışıyor. Piyasa likiditesi ve hacmi zirvede!',
      };
    }
    if (isTokyoOpen && isLondonOpen) {
      return {
        level: 'YÜKSEK VOLATİLİTE',
        badge: 'bg-amber-500/20 text-amber-400 border-amber-500/40',
        desc: 'Tokyo kapanışı ile Londra açılışı çakışıyor.',
      };
    }
    if (isSydneyOpen && isTokyoOpen) {
      return {
        level: 'ORTA VOLATİLİTE',
        badge: 'bg-blue-500/20 text-blue-400 border-blue-500/40',
        desc: 'Asya - Pasifik seansları aktif.',
      };
    }
    if (isLondonOpen || isNyOpen) {
      return {
        level: 'NORMAL VOLATİLİTE',
        badge: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/40',
        desc: 'Ana piyasalardan biri açık.',
      };
    }
    return {
      level: 'DÜŞÜK VOLATİLİTE / PİYASA KAPALI',
      badge: 'bg-slate-800 text-slate-400 border-slate-700',
      desc: 'Hafta sonu veya seans arası düşük likidite aralığı.',
    };
  };

  const vol = getVolatilityRating();

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Real-time World Clock Banner */}
      <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B26] to-[#10131B] border border-slate-800 shadow-xl space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <Clock className="w-5 h-5 text-cyan-400 animate-spin-slow" />
            <span className="text-sm font-bold text-white tracking-wide">CANLI DÜNYA SEANS SAATLERİ</span>
          </div>
          <div className="text-xs px-3 py-1 rounded-full bg-[#1B2232] border border-slate-700 text-slate-300 font-mono">
            TSİ (UTC+3): {now.toLocaleTimeString('tr-TR')}
          </div>
        </div>

        {/* Volatility Indicator */}
        <div className={`p-4 rounded-xl border ${vol.badge} space-y-1`}>
          <div className="flex items-center justify-between">
            <span className="font-extrabold text-sm tracking-wide">{vol.level}</span>
            <span className="text-xs font-bold">{getActiveSessionsCount()} Seans Aktif</span>
          </div>
          <p className="text-xs text-slate-300">{vol.desc}</p>
        </div>
      </div>

      {/* 24-Hour Timeline Representation */}
      <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
            24 Saatlik Seans Zaman Çizelgesi
          </h4>
          <span className="text-xs text-cyan-400 font-mono">Şu an: {trHour}:00 TSİ</span>
        </div>

        {/* Timeline Grid */}
        <div className="space-y-3">
          {sessions.map((session) => {
            const isOpen = isSessionOpen(session);
            return (
              <div key={session.city} className="space-y-1.5">
                <div className="flex justify-between text-xs font-medium">
                  <div className="flex items-center gap-2">
                    <span className="text-white font-bold">{session.name}</span>
                    <span className="text-slate-400">({session.country})</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-slate-400 font-mono">{session.openLocal} - {session.closeLocal}</span>
                    <span
                      className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        isOpen
                          ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                          : 'bg-slate-800 text-slate-500'
                      }`}
                    >
                      {isOpen ? 'AÇIK' : 'KAPALI'}
                    </span>
                  </div>
                </div>

                <div className="h-3 w-full bg-[#10131B] rounded-full overflow-hidden relative border border-slate-800/80">
                  {/* Session block representation */}
                  <div
                    className={`h-full bg-gradient-to-r ${session.accentColor} opacity-${
                      isOpen ? '90' : '30'
                    } rounded-full`}
                    style={{
                      width: '40%',
                      marginLeft: session.city === 'Sidney' ? '0%' : session.city === 'Tokyo' ? '12%' : session.city === 'Londra' ? '45%' : '65%',
                    }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Overlap & Trading Strategies Info */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="p-4 rounded-xl bg-[#141824] border border-slate-800 space-y-2">
          <div className="flex items-center gap-2 text-sm font-bold text-white">
            <Activity className="w-4 h-4 text-emerald-400" />
            Londra - New York Çakışması (16:30 - 19:30 TSİ)
          </div>
          <p className="text-xs text-slate-400 leading-relaxed">
            Günlük Forex ve Emtia işlem hacminin %70'inden fazlası bu saat aralığında gerçekleşir. EUR/USD, GBP/USD, Ons Altın ve Brent Petrol gibi varlıklarda en yoğun hareketlilik bu pencerede görülür.
          </p>
        </div>

        <div className="p-4 rounded-xl bg-[#141824] border border-slate-800 space-y-2">
          <div className="flex items-center gap-2 text-sm font-bold text-white">
            <Globe2 className="w-4 h-4 text-cyan-400" />
            Tokyo - Londra Çakışması (11:00 - 12:00 TSİ)
          </div>
          <p className="text-xs text-slate-400 leading-relaxed">
            Asya piyasalarının kapanışı ve Avrupa bankalarının açılışıyla özellikle GBP/JPY, USD/JPY ve EUR/JPY paritelerinde kırılım (breakout) fırsatları oluşur.
          </p>
        </div>
      </div>
    </div>
  );
};
