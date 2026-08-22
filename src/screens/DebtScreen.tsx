import React, { useState, useEffect } from 'react';
import { Plus, Trash2, CreditCard, DollarSign, Calendar, AlertCircle } from 'lucide-react';
import { StorageService } from '../services/storage';
import { Debt } from '../types';
import { AppFormatters } from '../utils/formatters';

export const DebtScreen: React.FC = () => {
  const [debts, setDebts] = useState<Debt[]>([]);
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState('');

  const loadData = () => {
    setDebts(StorageService.getDebts());
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAddDebt = (e: React.FormEvent) => {
    e.preventDefault();
    const parsedAmt = parseFloat(amount.replace(',', '.')) || 0;
    if (!description.trim() || parsedAmt <= 0) return;

    StorageService.addDebt(description.trim(), parsedAmt);
    setDescription('');
    setAmount('');
    loadData();
  };

  const handleDeleteDebt = (id: string) => {
    if (window.confirm('Bu borç kaydını silmek istediğinize emin misiniz?')) {
      StorageService.deleteDebt(id);
      loadData();
    }
  };

  const totalDebt = debts.reduce((sum, d) => sum + d.amount, 0);

  return (
    <div className="space-y-6 pb-24 animate-in fade-in duration-200">
      {/* Total Debt Banner */}
      <div className="p-6 rounded-2xl bg-gradient-to-br from-[#1F1418] to-[#121620] border border-red-500/20 shadow-xl space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold text-red-400 uppercase tracking-wider flex items-center gap-1.5">
            <CreditCard className="w-4 h-4" />
            Toplam Borç / Kredi Yükü
          </span>
          <span className="text-xs text-slate-400">{debts.length} Kayıtlı Kalem</span>
        </div>
        <div className="text-3xl font-extrabold text-red-400 font-mono">
          {AppFormatters.currency(totalDebt)}
        </div>
        <p className="text-xs text-slate-400">
          Bu tutar Genel Portföy ekranındaki "Net Varlık" hesaplamasında varlıklarınızdan otomatik olarak düşülür.
        </p>
      </div>

      {/* Add Debt Form */}
      <form onSubmit={handleAddDebt} className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-4">
        <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
          Yeni Borç / Yükümlülük Ekle
        </h4>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs text-slate-400 font-medium mb-1">Açıklama / Borç Adı</label>
            <input
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="örn. Kredi Kartı Ekstresi, Konut Kredisi"
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-red-500"
              required
            />
          </div>

          <div>
            <label className="block text-xs text-slate-400 font-medium mb-1">Tutar (₺)</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="örn. 15000"
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-sm focus:outline-none focus:border-red-500"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          className="px-4 py-2.5 bg-red-500 hover:bg-red-400 text-white font-bold text-xs rounded-xl transition flex items-center gap-1.5 shadow-md shadow-red-500/20"
        >
          <Plus className="w-4 h-4" />
          Borç Kaydı Ekle
        </button>
      </form>

      {/* Debt List */}
      <div className="space-y-3">
        <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider px-1">
          Mevcut Borç Kalemleri ({debts.length})
        </h4>

        {debts.length === 0 ? (
          <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400">
            Kayıtlı borç bulunmuyor.
          </div>
        ) : (
          <div className="space-y-2">
            {debts.map((debt) => (
              <div
                key={debt.id}
                className="p-4 rounded-xl bg-[#141824] border border-slate-800 flex items-center justify-between gap-3"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400">
                    <CreditCard className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="font-bold text-white text-sm">{debt.description}</div>
                    <div className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                      <Calendar className="w-3.5 h-3.5" />
                      {AppFormatters.date(debt.createdAt)}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <div className="text-base font-extrabold text-red-400 font-mono">
                    {AppFormatters.currency(debt.amount)}
                  </div>
                  <button
                    onClick={() => handleDeleteDebt(debt.id)}
                    className="p-1.5 text-slate-500 hover:text-red-400 transition"
                    title="Borcu Sil"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
