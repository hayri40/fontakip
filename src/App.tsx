import React, { useState } from 'react';
import { Header } from './components/Header';
import { HomeScreen } from './screens/HomeScreen';
import { GeneralPortfolioScreen } from './screens/GeneralPortfolioScreen';
import { FundScreen } from './screens/FundScreen';
import { StockScreen } from './screens/StockScreen';
import { FxScreen } from './screens/FxScreen';
import { ToolsScreen } from './screens/ToolsScreen';
import { DebtScreen } from './screens/DebtScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { TransactionModal } from './components/TransactionModal';
import { StorageService } from './services/storage';
import { TransactionType } from './types';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>('home');
  const [refreshKey, setRefreshKey] = useState<number>(0);

  // Transaction Modal State
  const [isTxModalOpen, setIsTxModalOpen] = useState(false);
  const [txTargetType, setTxTargetType] = useState<'fund' | 'stock'>('fund');
  const [txTargetCode, setTxTargetCode] = useState('');
  const [txCurrentPrice, setTxCurrentPrice] = useState(0);

  const handleOpenFundTransaction = (fundCode?: string, currentPrice?: number) => {
    setTxTargetType('fund');
    setTxTargetCode(fundCode || '');
    setTxCurrentPrice(currentPrice || 0);
    setIsTxModalOpen(true);
  };

  const handleOpenStockTransaction = (stockSymbol?: string, currentPrice?: number) => {
    setTxTargetType('stock');
    setTxTargetCode(stockSymbol || '');
    setTxCurrentPrice(currentPrice || 0);
    setIsTxModalOpen(true);
  };

  const handleSaveTransaction = (data: {
    code: string;
    date: string;
    type: TransactionType;
    quantity: number;
    unitPrice: number;
  }) => {
    if (txTargetType === 'fund') {
      StorageService.addFundTransaction({
        fundCode: data.code,
        date: data.date,
        type: data.type,
        quantity: data.quantity,
        unitPrice: data.unitPrice,
      });
    } else {
      StorageService.addStockTransaction({
        stockSymbol: data.code,
        date: data.date,
        type: data.type,
        quantity: data.quantity,
        unitPrice: data.unitPrice,
      });
    }

    setRefreshKey((k) => k + 1);
  };

  const renderScreen = () => {
    switch (activeTab) {
      case 'home':
        return <HomeScreen onNavigate={(screen) => setActiveTab(screen)} />;
      case 'general':
        return (
          <div className="flex-1 flex flex-col">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
              <GeneralPortfolioScreen
                key={refreshKey}
                onNavigate={(tab) => setActiveTab(tab)}
                onOpenFundTransaction={handleOpenFundTransaction}
                onOpenStockTransaction={handleOpenStockTransaction}
              />
            </main>
          </div>
        );
      case 'fund':
        return (
          <div className="flex-1 flex flex-col">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
              <FundScreen key={refreshKey} onOpenTransaction={handleOpenFundTransaction} />
            </main>
          </div>
        );
      case 'stock':
        return (
          <div className="flex-1 flex flex-col">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
              <StockScreen key={refreshKey} onOpenTransaction={handleOpenStockTransaction} />
            </main>
          </div>
        );
      case 'fx':
        return (
          <div className="flex-1 flex flex-col min-h-0">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-6xl w-full mx-auto p-2 sm:p-4 flex flex-col">
              <FxScreen key={refreshKey} />
            </main>
          </div>
        );
      case 'tools':
        return (
          <div className="flex-1 flex flex-col">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
              <ToolsScreen key={refreshKey} />
            </main>
          </div>
        );
      case 'debts':
        return (
          <div className="flex-1 flex flex-col">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
              <DebtScreen key={refreshKey} />
            </main>
          </div>
        );
      case 'settings':
        return (
          <div className="flex-1 flex flex-col">
            <Header activeTab={activeTab} onBack={() => setActiveTab('home')} />
            <main className="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
              <SettingsScreen key={refreshKey} />
            </main>
          </div>
        );
      default:
        return <HomeScreen onNavigate={(screen) => setActiveTab(screen)} />;
    }
  };

  return (
    <div className="min-h-screen bg-[#0F1117] text-slate-100 flex flex-col selection:bg-cyan-500 selection:text-black">
      {renderScreen()}

      {/* Global Transaction Modal */}
      <TransactionModal
        isOpen={isTxModalOpen}
        onClose={() => setIsTxModalOpen(false)}
        targetType={txTargetType}
        targetCode={txTargetCode}
        currentPrice={txCurrentPrice}
        onSubmit={handleSaveTransaction}
      />
    </div>
  );
};
