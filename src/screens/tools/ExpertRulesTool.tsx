import React, { useState, useEffect } from 'react';
import {
  ShieldCheck,
  Plus,
  Trash2,
  Edit2,
  Check,
  X,
  Search,
  BookOpen,
  Sparkles,
  RefreshCw,
  AlertCircle,
  Brain,
  Sliders,
  CheckCircle2,
} from 'lucide-react';
import { ExpertRule, ExpertRuleCategory } from '../../types';
import { StorageService, defaultExpertRules } from '../../services/storage';

const CATEGORIES: ExpertRuleCategory[] = [
  'Risk Yönetimi',
  'Giriş ve Çıkış Stratejisi',
  'Parite & Volatilite',
  'Zaman Dilimi & Seanslar',
  'Psikoloji & Disiplin',
  'Genel Kural',
];

const CATEGORY_COLORS: Record<ExpertRuleCategory, { bg: string; text: string; border: string }> = {
  'Risk Yönetimi': {
    bg: 'bg-red-500/10',
    text: 'text-red-400',
    border: 'border-red-500/20',
  },
  'Giriş ve Çıkış Stratejisi': {
    bg: 'bg-emerald-500/10',
    text: 'text-emerald-400',
    border: 'border-emerald-500/20',
  },
  'Parite & Volatilite': {
    bg: 'bg-amber-500/10',
    text: 'text-amber-400',
    border: 'border-amber-500/20',
  },
  'Zaman Dilimi & Seanslar': {
    bg: 'bg-blue-500/10',
    text: 'text-blue-400',
    border: 'border-blue-500/20',
  },
  'Psikoloji & Disiplin': {
    bg: 'bg-purple-500/10',
    text: 'text-purple-400',
    border: 'border-purple-500/20',
  },
  'Genel Kural': {
    bg: 'bg-cyan-500/10',
    text: 'text-cyan-400',
    border: 'border-cyan-500/20',
  },
};

export const ExpertRulesTool: React.FC = () => {
  const [rules, setRules] = useState<ExpertRule[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [isAdding, setIsAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  // Form State
  const [formTitle, setFormTitle] = useState('');
  const [formRule, setFormRule] = useState('');
  const [formCategory, setFormCategory] = useState<ExpertRuleCategory>('Risk Yönetimi');
  const [notification, setNotification] = useState<string | null>(null);

  useEffect(() => {
    loadRules();
  }, []);

  const loadRules = () => {
    const data = StorageService.getExpertRules();
    setRules(data);
  };

  const showToast = (msg: string) => {
    setNotification(msg);
    setTimeout(() => setNotification(null), 3000);
  };

  const handleToggle = (id: string) => {
    StorageService.toggleExpertRule(id);
    loadRules();
  };

  const handleDelete = (id: string) => {
    if (confirm('Bu kuralı silmek istediğinize emin misiniz? Uzman bu kuralı artık dikkate almayacaktır.')) {
      StorageService.deleteExpertRule(id);
      loadRules();
      showToast('Kural başarıyla silindi.');
    }
  };

  const handleStartEdit = (r: ExpertRule) => {
    setEditingId(r.id);
    setFormTitle(r.title);
    setFormRule(r.rule);
    setFormCategory(r.category);
    setIsAdding(false);
  };

  const handleSaveForm = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim() || !formRule.trim()) return;

    if (editingId) {
      StorageService.updateExpertRule(editingId, {
        title: formTitle.trim(),
        rule: formRule.trim(),
        category: formCategory,
      });
      showToast('Kural güncellendi.');
      setEditingId(null);
    } else {
      StorageService.addExpertRule({
        title: formTitle.trim(),
        rule: formRule.trim(),
        category: formCategory,
        isActive: true,
        sourceContext: 'Kullanıcı tarafından elle eklendi',
      });
      showToast('Yeni kural uzmanın hafızasına eklendi.');
      setIsAdding(false);
    }

    setFormTitle('');
    setFormRule('');
    setFormCategory('Risk Yönetimi');
    loadRules();
  };

  const handleResetDefaults = () => {
    if (confirm('Tüm kuralları varsayılan uzman kurallarına sıfırlamak istiyor musunuz?')) {
      StorageService.saveExpertRules(defaultExpertRules);
      loadRules();
      showToast('Kurallar varsayılana sıfırlandı.');
    }
  };

  const filteredRules = rules.filter((r) => {
    const matchesCategory = selectedCategory === 'all' || r.category === selectedCategory;
    const matchesSearch =
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.rule.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const activeCount = rules.filter((r) => r.isActive).length;

  return (
    <div className="space-y-5 animate-in fade-in duration-200">
      {/* Toast Notification */}
      {notification && (
        <div className="fixed top-4 right-4 z-50 bg-emerald-500/90 text-white px-4 py-2.5 rounded-xl shadow-2xl flex items-center gap-2 text-xs font-semibold backdrop-blur-md animate-in slide-in-from-top duration-300">
          <CheckCircle2 className="w-4 h-4 text-white" />
          <span>{notification}</span>
        </div>
      )}

      {/* Hero Overview Header */}
      <div className="p-5 rounded-2xl bg-gradient-to-br from-[#161B28] via-[#121622] to-[#0E1118] border border-slate-800/80 shadow-xl relative overflow-hidden">
        <div className="absolute right-0 top-0 w-64 h-64 bg-cyan-500/5 rounded-full blur-3xl pointer-events-none" />
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 relative z-10">
          <div className="flex items-start gap-3.5">
            <div className="p-3 rounded-2xl bg-cyan-500/10 border border-cyan-500/20 text-cyan-400">
              <Brain className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-bold text-white">Uzman FX Kuralları & Hafıza</h2>
                <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-cyan-500/15 text-cyan-400 border border-cyan-500/30">
                  Canlı Entegre
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-1 max-w-xl leading-relaxed">
                FX ekranında uzmanınızla sohbet ederken konuştuğunuz veya kararlaştırdığınız tüm kurallar burada otomatik listelenir ve sonraki tüm analizlerde titizlikle uygulanır.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => {
                setIsAdding(!isAdding);
                setEditingId(null);
                setFormTitle('');
                setFormRule('');
              }}
              className="px-3.5 py-2 rounded-xl bg-cyan-600 hover:bg-cyan-500 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-lg shadow-cyan-900/30 active:scale-95"
            >
              <Plus className="w-4 h-4" />
              <span>Yeni Kural Ekle</span>
            </button>
            <button
              onClick={handleResetDefaults}
              title="Varsayılan Kurallara Sıfırla"
              className="p-2 rounded-xl bg-[#141824] hover:bg-[#1C2234] border border-slate-800 text-slate-400 hover:text-white transition"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Stats Strip */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 mt-5 pt-4 border-t border-slate-800/60">
          <div className="bg-[#0F121C] p-2.5 rounded-xl border border-slate-800/50">
            <div className="text-[11px] text-slate-400">Toplam Kural</div>
            <div className="text-base font-extrabold text-white mt-0.5">{rules.length}</div>
          </div>
          <div className="bg-[#0F121C] p-2.5 rounded-xl border border-slate-800/50">
            <div className="text-[11px] text-slate-400">Aktif Uygulanan</div>
            <div className="text-base font-extrabold text-emerald-400 mt-0.5">{activeCount}</div>
          </div>
          <div className="bg-[#0F121C] p-2.5 rounded-xl border border-slate-800/50">
            <div className="text-[11px] text-slate-400">Hedef Parite</div>
            <div className="text-base font-extrabold text-cyan-400 mt-0.5">GBPCAD & FX</div>
          </div>
          <div className="bg-[#0F121C] p-2.5 rounded-xl border border-slate-800/50">
            <div className="text-[11px] text-slate-400">Öğrenme Durumu</div>
            <div className="text-base font-extrabold text-purple-400 mt-0.5 flex items-center gap-1">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Daima Açık</span>
            </div>
          </div>
        </div>
      </div>

      {/* Add / Edit Rule Card Form */}
      {(isAdding || editingId) && (
        <form
          onSubmit={handleSaveForm}
          className="p-4 sm:p-5 rounded-2xl bg-[#141824] border border-cyan-500/30 shadow-2xl space-y-4 animate-in fade-in duration-200"
        >
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              {editingId ? <Edit2 className="w-4 h-4 text-cyan-400" /> : <Plus className="w-4 h-4 text-cyan-400" />}
              <span>{editingId ? 'Kuralı Düzenle' : 'Yeni Uzman Kuralı Tanımla'}</span>
            </h3>
            <button
              type="button"
              onClick={() => {
                setIsAdding(false);
                setEditingId(null);
              }}
              className="text-slate-400 hover:text-white p-1 rounded-lg"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="sm:col-span-2 space-y-1">
              <label className="text-[11px] font-semibold text-slate-300">Kural Başlığı / Adı</label>
              <input
                type="text"
                placeholder="Örn: 1:2 R:R Olmadan Giriş Yapma"
                value={formTitle}
                onChange={(e) => setFormTitle(e.target.value)}
                className="w-full bg-[#0F121C] border border-slate-700 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-cyan-500"
                required
              />
            </div>
            <div className="space-y-1">
              <label className="text-[11px] font-semibold text-slate-300">Kategori</label>
              <select
                value={formCategory}
                onChange={(e) => setFormCategory(e.target.value as ExpertRuleCategory)}
                className="w-full bg-[#0F121C] border border-slate-700 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-cyan-500"
              >
                {CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="space-y-1">
            <label className="text-[11px] font-semibold text-slate-300">Kuralın Net Tanımı ve İlkesi</label>
            <textarea
              rows={3}
              placeholder="Uzmanın analiz ve işlemlerinde kesinlikle uyacağı kuralın detaylarını yazın..."
              value={formRule}
              onChange={(e) => setFormRule(e.target.value)}
              className="w-full bg-[#0F121C] border border-slate-700 rounded-xl p-3 text-xs text-white focus:outline-none focus:border-cyan-500 leading-relaxed"
              required
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => {
                setIsAdding(false);
                setEditingId(null);
              }}
              className="px-3.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold"
            >
              İptal
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 rounded-xl bg-cyan-600 hover:bg-cyan-500 text-white text-xs font-bold flex items-center gap-1.5"
            >
              <Check className="w-3.5 h-3.5" />
              <span>{editingId ? 'Güncelle' : 'Kuralı Kaydet'}</span>
            </button>
          </div>
        </form>
      )}

      {/* Filters and Search Bar */}
      <div className="flex flex-col sm:flex-row gap-2.5 items-stretch sm:items-center justify-between">
        {/* Search */}
        <div className="relative flex-1 max-w-sm">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Kurallar arasında ara..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-2 bg-[#141824] border border-slate-800 rounded-xl text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-cyan-500"
          />
        </div>

        {/* Category Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0 scrollbar-none">
          <button
            onClick={() => setSelectedCategory('all')}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition ${
              selectedCategory === 'all'
                ? 'bg-white text-slate-900 shadow-md'
                : 'bg-[#141824] text-slate-400 hover:text-white border border-slate-800'
            }`}
          >
            Tümü ({rules.length})
          </button>
          {CATEGORIES.map((cat) => {
            const count = rules.filter((r) => r.category === cat).length;
            return (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-2.5 py-1.5 rounded-xl text-xs font-medium whitespace-nowrap transition flex items-center gap-1.5 ${
                  selectedCategory === cat
                    ? 'bg-cyan-600 text-white shadow-md font-bold'
                    : 'bg-[#141824] text-slate-400 hover:text-white border border-slate-800'
                }`}
              >
                <span>{cat}</span>
                <span className="text-[10px] opacity-75">({count})</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Rules Grid / List */}
      {filteredRules.length === 0 ? (
        <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 space-y-3">
          <BookOpen className="w-8 h-8 text-slate-600 mx-auto" />
          <p className="text-xs text-slate-400">Aramanıza veya seçilen kategoriye uygun kural bulunamadı.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
          {filteredRules.map((rule) => {
            const catColor = CATEGORY_COLORS[rule.category] || CATEGORY_COLORS['Genel Kural'];
            return (
              <div
                key={rule.id}
                className={`p-4 rounded-2xl bg-[#141824] border transition duration-200 flex flex-col justify-between gap-3 shadow-lg ${
                  rule.isActive ? 'border-slate-800 hover:border-slate-700' : 'border-slate-800/40 opacity-60'
                }`}
              >
                <div>
                  {/* Category & Status */}
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${catColor.bg} ${catColor.text} ${catColor.border}`}
                    >
                      {rule.category}
                    </span>

                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => handleToggle(rule.id)}
                        className={`text-[10px] px-2 py-0.5 rounded-full font-bold transition flex items-center gap-1 ${
                          rule.isActive
                            ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                            : 'bg-slate-800 text-slate-400 border border-slate-700'
                        }`}
                        title={rule.isActive ? 'Kuralı Devre Dışı Bırak' : 'Kuralı Aktif Et'}
                      >
                        <span className={`w-1.5 h-1.5 rounded-full ${rule.isActive ? 'bg-emerald-400' : 'bg-slate-500'}`} />
                        <span>{rule.isActive ? 'Aktif' : 'Pasif'}</span>
                      </button>
                    </div>
                  </div>

                  {/* Title */}
                  <h4 className="text-sm font-bold text-white">{rule.title}</h4>

                  {/* Rule Body */}
                  <p className="text-xs text-slate-300 mt-1.5 leading-relaxed bg-[#0F121C] p-2.5 rounded-xl border border-slate-800/60 font-sans">
                    {rule.rule}
                  </p>

                  {/* Source Context */}
                  {rule.sourceContext && (
                    <div className="text-[10px] text-slate-500 mt-2 flex items-center gap-1">
                      <Sparkles className="w-3 h-3 text-cyan-400/70" />
                      <span>{rule.sourceContext}</span>
                    </div>
                  )}
                </div>

                {/* Footer Controls */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-800/60 text-[11px] text-slate-500">
                  <span>{new Date(rule.createdAt).toLocaleDateString('tr-TR')}</span>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleStartEdit(rule)}
                      className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition"
                      title="Düzenle"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => handleDelete(rule.id)}
                      className="p-1.5 rounded-lg bg-slate-800 hover:bg-red-950/60 text-slate-300 hover:text-red-400 transition"
                      title="Sil"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
