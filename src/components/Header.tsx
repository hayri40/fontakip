import React from 'react';
import { ArrowLeft } from 'lucide-react';

interface HeaderProps {
  activeTab: string;
  totalNetWorth?: number;
  onBack?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ activeTab, onBack }) => {
  const getTitle = () => {
    switch (activeTab) {
      case 'home':
        return 'Finans Merkezi';
      case 'general':
        return 'Genel Portföyüm';
      case 'fund':
        return 'FON';
      case 'stock':
        return 'HİSSE';
      case 'fx':
        return 'FX';
      case 'tools':
        return 'ARAÇLAR';
      case 'debts':
        return 'Borçlarım';
      case 'settings':
        return 'AYARLAR';
      default:
        return 'Finans Merkezi';
    }
  };

  return (
    <header className="sticky top-0 z-30 bg-[#161922] border-b border-slate-800/80 px-4 h-14 flex items-center shadow-md">
      <div className="max-w-4xl w-full mx-auto relative flex items-center justify-center">
        {activeTab !== 'home' && onBack && (
          <button
            onClick={onBack}
            className="absolute left-0 p-2 text-slate-300 hover:text-white hover:bg-slate-800/60 rounded-full transition active:scale-95"
            aria-label="Geri"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
        )}
        <h1 className="text-lg sm:text-xl font-bold text-white tracking-wide text-center">
          {getTitle()}
        </h1>
      </div>
    </header>
  );
};
