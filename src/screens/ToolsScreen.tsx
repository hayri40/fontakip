import React, { useState } from 'react';
import {
  Clock,
  PieChart,
  Scale,
  Calculator,
  Activity,
  FileText,
  ChevronRight,
  ArrowLeft,
  Wrench,
  Brain,
} from 'lucide-react';
import { GlobalMarketHours } from './tools/GlobalMarketHours';
import { InvestmentPlanner } from './tools/InvestmentPlanner';
import { PortfolioBalancer } from './tools/PortfolioBalancer';
import { CompoundCalculator } from './tools/CompoundCalculator';
import { PerformanceTracker } from './tools/PerformanceTracker';
import { NotesTool } from './tools/NotesTool';
import { ExpertRulesTool } from './tools/ExpertRulesTool';

type ToolId = 'rules' | 'hours' | 'planner' | 'balancer' | 'compound' | 'performance' | 'notes';

interface ToolItem {
  id: ToolId;
  title: string;
  subtitle: string;
  icon: React.ElementType;
  badge?: string;
  color: string;
  border: string;
}

export const ToolsScreen: React.FC = () => {
  const [selectedTool, setSelectedTool] = useState<ToolId | null>(null);

  const tools: ToolItem[] = [
    {
      id: 'rules',
      title: 'Uzman FX Kuralları & Hafıza',
      subtitle: 'FX Baş Stratejistinin sizinle öğrendiği tüm analiz ve risk yönetimi kuralları',
      icon: Brain,
      badge: 'YAPAY ZEKA',
      color: 'bg-cyan-500/10 text-cyan-400',
      border: 'border-cyan-500/20 hover:border-cyan-500/50',
    },
    {
      id: 'hours',
      title: 'Forex Seans Rehberi',
      subtitle: 'Dünya borsaları canlı seans saatleri, çakışmalar ve volatilite',
      icon: Clock,
      badge: 'CANLI',
      color: 'bg-blue-500/10 text-blue-400',
      border: 'border-blue-500/20 hover:border-blue-500/50',
    },
    {
      id: 'planner',
      title: 'Yatırım Dağıtım Planlayıcı',
      subtitle: 'Aylık yatırım bütçenizi Fon, Hisse ve FX arasında paylaştırın',
      icon: PieChart,
      color: 'bg-cyan-500/10 text-cyan-400',
      border: 'border-cyan-500/20 hover:border-cyan-500/50',
    },
    {
      id: 'balancer',
      title: 'Portföy Dengeleyici',
      subtitle: 'Hedef dağılıma satış yapmadan yeni ek bütçeyle ulaşın',
      icon: Scale,
      color: 'bg-emerald-500/10 text-emerald-400',
      border: 'border-emerald-500/20 hover:border-emerald-500/50',
    },
    {
      id: 'compound',
      title: 'Bileşik Getiri Hesaplayıcı',
      subtitle: 'Gelecekteki portföy büyüklüğünüzü ve bileşik faiz gücünü hesaplayın',
      icon: Calculator,
      color: 'bg-purple-500/10 text-purple-400',
      border: 'border-purple-500/20 hover:border-purple-500/50',
    },
    {
      id: 'performance',
      title: 'Performans Takibi',
      subtitle: 'Portföy büyüme hedefleriniz ile gerçekleşenleri karşılaştırın',
      icon: Activity,
      color: 'bg-amber-500/10 text-amber-400',
      border: 'border-amber-500/20 hover:border-amber-500/50',
    },
    {
      id: 'notes',
      title: 'Notlarım & Stratejiler',
      subtitle: 'Yatırım fikirlerinizi, hisse analizlerinizi ve tezlerinizi kaydedin',
      icon: FileText,
      color: 'bg-rose-500/10 text-rose-400',
      border: 'border-rose-500/20 hover:border-rose-500/50',
    },
  ];

  const renderActiveTool = () => {
    switch (selectedTool) {
      case 'rules':
        return <ExpertRulesTool />;
      case 'hours':
        return <GlobalMarketHours />;
      case 'planner':
        return <InvestmentPlanner />;
      case 'balancer':
        return <PortfolioBalancer />;
      case 'compound':
        return <CompoundCalculator />;
      case 'performance':
        return <PerformanceTracker />;
      case 'notes':
        return <NotesTool />;
      default:
        return null;
    }
  };


  const activeToolObj = tools.find((t) => t.id === selectedTool);

  return (
    <div className="space-y-6 pb-24 animate-in fade-in duration-200">
      {selectedTool ? (
        <div className="space-y-4">
          <div className="flex items-center gap-3 border-b border-slate-800 pb-3">
            <button
              onClick={() => setSelectedTool(null)}
              className="p-2 rounded-xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 text-slate-300 hover:text-white transition flex items-center gap-1.5 text-xs font-semibold"
            >
              <ArrowLeft className="w-4 h-4" />
              Tüm Araçlar
            </button>
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              {activeToolObj?.title}
            </h2>
          </div>
          {renderActiveTool()}
        </div>
      ) : (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-bold text-white flex items-center gap-2">
                <Wrench className="w-5 h-5 text-cyan-400" />
                Finansal Yatırım & Analiz Araçları
              </h2>
              <p className="text-xs text-slate-400 mt-0.5">
                Portföyünüzü optimize etmek ve bilinçli kararlar almak için geliştirilmiş araçlar
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
            {tools.map((tool) => {
              const Icon = tool.icon;
              return (
                <div
                  key={tool.id}
                  onClick={() => setSelectedTool(tool.id)}
                  className={`p-5 rounded-2xl bg-[#141824] hover:bg-[#181E2E] border ${tool.border} transition duration-200 cursor-pointer flex items-center justify-between gap-4 group shadow-lg`}
                >
                  <div className="flex items-start gap-3.5">
                    <div className={`p-3 rounded-2xl ${tool.color} border border-white/5`}>
                      <Icon className="w-6 h-6" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="font-bold text-white text-sm sm:text-base group-hover:text-cyan-400 transition">
                          {tool.title}
                        </h3>
                        {tool.badge && (
                          <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 animate-pulse">
                            {tool.badge}
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-400 mt-1 leading-relaxed line-clamp-2">
                        {tool.subtitle}
                      </p>
                    </div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-slate-600 group-hover:text-cyan-400 transition shrink-0" />
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
