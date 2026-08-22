import React from 'react';
import {
  PieChart,
  Layers,
  TrendingUp,
  Coins,
  Wrench,
  Settings,
  CreditCard,
} from 'lucide-react';

interface NavigationProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export const Navigation: React.FC<NavigationProps> = ({ activeTab, onTabChange }) => {
  const tabs = [
    { id: 'general', label: 'Genel', icon: PieChart },
    { id: 'fund', label: 'Fon', icon: Layers },
    { id: 'stock', label: 'Hisse', icon: TrendingUp },
    { id: 'fx', label: 'FX & Emtia', icon: Coins },
    { id: 'tools', label: 'Araçlar', icon: Wrench },
    { id: 'settings', label: 'Ayarlar', icon: Settings },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#131722]/95 backdrop-blur-lg border-t border-slate-800/90 pb-safe">
      <div className="max-w-md md:max-w-2xl mx-auto px-2 py-1.5 flex items-center justify-around">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`flex flex-col items-center justify-center py-1.5 px-3 rounded-xl transition-all duration-200 ${
                isActive
                  ? 'text-cyan-400 bg-cyan-500/10 font-semibold scale-105'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <Icon className={`w-5 h-5 mb-0.5 ${isActive ? 'stroke-[2.2px]' : 'stroke-[1.8px]'}`} />
              <span className="text-[11px] leading-tight">{tab.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
