import React from 'react';
import {
  Home,
  Building2,
  TrendingUp,
  RefreshCw,
  Calculator,
  Settings,
  LogOut,
  ChevronRight,
} from 'lucide-react';

interface HomeScreenProps {
  onNavigate: (screen: string) => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigate }) => {
  const menuItems = [
    {
      id: 'fund',
      title: 'FON',
      subtitle: 'Portföy ve Fon Takibi',
      icon: Building2,
      color: 'text-green-500',
      bgColor: 'bg-green-500/10',
    },
    {
      id: 'stock',
      title: 'HİSSE',
      subtitle: 'Borsa İstanbul',
      icon: TrendingUp,
      color: 'text-blue-500',
      bgColor: 'bg-blue-500/10',
    },
    {
      id: 'fx',
      title: 'FX',
      subtitle: 'Döviz, emtia ve kripto takibi',
      icon: RefreshCw,
      color: 'text-orange-500',
      bgColor: 'bg-orange-500/10',
    },
    {
      id: 'tools',
      title: 'ARAÇLAR',
      subtitle: 'Finansal araçlar ve planlama',
      icon: Calculator,
      color: 'text-purple-500',
      bgColor: 'bg-purple-500/10',
    },
    {
      id: 'settings',
      title: 'AYARLAR',
      subtitle: 'Veri ve uygulama ayarları',
      icon: Settings,
      color: 'text-slate-400',
      bgColor: 'bg-slate-500/10',
    },
    {
      id: 'exit',
      title: 'ÇIKIŞ',
      subtitle: 'Uygulamadan Çık',
      icon: LogOut,
      color: 'text-red-500',
      bgColor: 'bg-red-500/10',
    },
  ];

  return (
    <div className="min-h-screen bg-[#0F1117] text-white flex flex-col">
      {/* Top Flutter Style AppBar */}
      <header className="h-16 flex items-center justify-center border-b border-slate-800/80 bg-[#161922] px-4 shadow-sm">
        <h1 className="text-xl font-bold tracking-tight text-white">Finans Merkezi</h1>
      </header>

      {/* Body List of Cards */}
      <main className="flex-1 max-w-2xl w-full mx-auto p-4 sm:p-6 space-y-3">
        {/* Card 1: Genel Portföyüm */}
        <div
          onClick={() => onNavigate('general')}
          className="bg-[#1A1D24] hover:bg-[#222630] border border-slate-800/80 rounded-2xl p-5 cursor-pointer transition-all duration-150 flex items-center justify-between shadow-lg shadow-black/20 group active:scale-[0.99]"
        >
          <div className="flex items-center gap-4">
            <div className="p-3 rounded-xl bg-cyan-500/10 text-cyan-400 group-hover:scale-105 transition-transform">
              <Home className="w-8 h-8" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white group-hover:text-cyan-400 transition-colors">
                🏠 Genel Portföyüm
              </h2>
            </div>
          </div>
          <ChevronRight className="w-6 h-6 text-slate-500 group-hover:text-white transition-colors" />
        </div>

        {/* Other Menu Cards */}
        {menuItems.map((item) => {
          const Icon = item.icon;
          return (
            <div
              key={item.id}
              onClick={() => {
                if (item.id === 'exit') {
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                } else {
                  onNavigate(item.id);
                }
              }}
              className="bg-[#1A1D24] hover:bg-[#222630] border border-slate-800/80 rounded-2xl px-5 py-4 cursor-pointer transition-all duration-150 flex items-center justify-between shadow-lg shadow-black/20 group active:scale-[0.99]"
            >
              <div className="flex items-center gap-4">
                <div className={`p-3 rounded-xl ${item.bgColor} ${item.color} group-hover:scale-105 transition-transform`}>
                  <Icon className="w-8 h-8" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white tracking-wide group-hover:text-cyan-400 transition-colors">
                    {item.title}
                  </h3>
                  <p className="text-xs text-slate-400 font-medium">
                    {item.subtitle}
                  </p>
                </div>
              </div>
              <ChevronRight className="w-6 h-6 text-slate-500 group-hover:text-white transition-colors" />
            </div>
          );
        })}
      </main>
    </div>
  );
};
