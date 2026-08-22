import React, { useState, useEffect } from 'react';
import { X, ArrowDownRight, ArrowUpRight, Calendar, DollarSign, Hash, CheckCircle2 } from 'lucide-react';
import { TransactionType } from '../types';
import { AppFormatters } from '../utils/formatters';
import { MarketDataService } from '../services/marketData';

interface TransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  targetType: 'fund' | 'stock';
  targetCode: string;
  currentPrice: number;
  onSubmit: (data: {
    code: string;
    date: string;
    type: TransactionType;
    quantity: number;
    unitPrice: number;
  }) => void;
}

export const TransactionModal: React.FC<TransactionModalProps> = ({
  isOpen,
  onClose,
  targetType,
  targetCode,
  currentPrice,
  onSubmit,
}) => {
  const [code, setCode] = useState(targetCode || '');
  const [targetName, setTargetName] = useState<string>('');
  const [type, setType] = useState<TransactionType>('BUY');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [quantity, setQuantity] = useState<string>('');
  const [unitPrice, setUnitPrice] = useState<string>(currentPrice > 0 ? currentPrice.toString() : '');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setCode(targetCode || '');
      setUnitPrice(currentPrice > 0 ? currentPrice.toString() : '');
      setQuantity('');
      setError(null);
      if (targetCode) {
        handleCodeChange(targetCode);
      }
    }
  }, [isOpen, targetCode, currentPrice]);

  const handleCodeChange = async (val: string) => {
    const clean = val.toUpperCase();
    setCode(clean);
    if (targetType === 'fund' && clean.length >= 3) {
      try {
        const detail = await MarketDataService.getFundDetail(clean);
        if (detail) {
          setTargetName(detail.name);
          if (!unitPrice || unitPrice === '0') {
            setUnitPrice(detail.currentPrice.toString());
          }
        }
      } catch {
        // ignore
      }
    } else if (targetType === 'stock' && clean.length >= 3) {
      const stock = MarketDataService.getStockDetail(clean);
      if (stock) {
        setTargetName(stock.name);
        if (!unitPrice || unitPrice === '0') {
          setUnitPrice(stock.currentPrice.toString());
        }
      }
    }
  };

  if (!isOpen) return null;

  const parsedQty = parseFloat(quantity.replace(',', '.')) || 0;
  const parsedPrice = parseFloat(unitPrice.replace(',', '.')) || 0;
  const totalAmount = parsedQty * parsedPrice;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim()) {
      setError(targetType === 'fund' ? 'Lütfen fon kodu girin.' : 'Lütfen hisse sembolü girin.');
      return;
    }
    if (parsedQty <= 0) {
      setError('Lütfen geçerli bir adet girin.');
      return;
    }
    if (parsedPrice <= 0) {
      setError('Lütfen geçerli bir birim fiyat girin.');
      return;
    }

    onSubmit({
      code: code.trim().toUpperCase(),
      date,
      type,
      quantity: parsedQty,
      unitPrice: parsedPrice,
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-[#181C27] border border-slate-700/80 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-800 bg-[#131722]">
          <div className="flex items-center gap-2">
            <div className={`p-2 rounded-lg ${type === 'BUY' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'}`}>
              {type === 'BUY' ? <ArrowDownRight className="w-5 h-5" /> : <ArrowUpRight className="w-5 h-5" />}
            </div>
            <div>
              <h3 className="font-bold text-white text-base">
                {type === 'BUY' ? 'Alış İşlemi Ekle' : 'Satış İşlemi Ekle'}
              </h3>
              <p className="text-xs text-slate-400">
                {targetType === 'fund' ? 'TEFAS Fon Alım / Satımı' : 'Borsa İstanbul Hisse Alım / Satımı'}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-5 space-y-4">
          {/* Type Selector */}
          <div className="grid grid-cols-2 gap-2 p-1 bg-[#10131B] rounded-xl border border-slate-800">
            <button
              type="button"
              onClick={() => setType('BUY')}
              className={`py-2 text-sm font-semibold rounded-lg transition-all ${
                type === 'BUY'
                  ? 'bg-emerald-600 text-white shadow-md shadow-emerald-900/30'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Alış (Portföye Ekle)
            </button>
            <button
              type="button"
              onClick={() => setType('SELL')}
              className={`py-2 text-sm font-semibold rounded-lg transition-all ${
                type === 'SELL'
                  ? 'bg-red-600 text-white shadow-md shadow-red-900/30'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Satış (Portföyden Çıkar)
            </button>
          </div>

          {/* Code */}
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              {targetType === 'fund' ? 'Fon Kodu' : 'Hisse Sembolü'}
            </label>
            <input
              type="text"
              value={code}
              onChange={(e) => handleCodeChange(e.target.value)}
              placeholder={targetType === 'fund' ? 'örn. KLU, TTE, MAC, KZL, AFT' : 'örn. THYAO, ASELS, TUPRS'}
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700/80 rounded-xl text-white font-mono uppercase focus:outline-none focus:border-cyan-500 text-sm"
              required
            />
            {targetName && (
              <p className="text-[11px] text-cyan-400 mt-1 flex items-center gap-1 font-medium truncate">
                <CheckCircle2 className="w-3 h-3 flex-shrink-0" />
                {targetName}
              </p>
            )}
          </div>

          {/* Date */}
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-slate-400" />
              İşlem Tarihi
            </label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700/80 rounded-xl text-white text-sm focus:outline-none focus:border-cyan-500"
              required
            />
          </div>

          {/* Quantity & Unit Price */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
                <Hash className="w-3.5 h-3.5 text-slate-400" />
                Adet / Pay
              </label>
              <input
                type="number"
                step="any"
                min="0"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                placeholder="100"
                className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700/80 rounded-xl text-white text-sm focus:outline-none focus:border-cyan-500"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
                <DollarSign className="w-3.5 h-3.5 text-slate-400" />
                Birim Fiyat (₺)
              </label>
              <input
                type="number"
                step="any"
                min="0"
                value={unitPrice}
                onChange={(e) => setUnitPrice(e.target.value)}
                placeholder="0.00"
                className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700/80 rounded-xl text-white text-sm focus:outline-none focus:border-cyan-500"
                required
              />
            </div>
          </div>

          {/* Total Amount Summary */}
          <div className="p-3.5 rounded-xl bg-[#10131B] border border-slate-800 flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Toplam İşlem Tutarı</span>
            <span className="text-base font-bold text-cyan-400 font-mono">
              {AppFormatters.currency(totalAmount)}
            </span>
          </div>

          {error && (
            <div className="p-3 rounded-lg bg-red-500/10 border border-red-500/30 text-red-400 text-xs">
              {error}
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex items-center gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 px-4 rounded-xl border border-slate-700 hover:bg-slate-800 text-slate-300 text-sm font-semibold transition"
            >
              İptal
            </button>
            <button
              type="submit"
              className={`flex-1 py-2.5 px-4 rounded-xl font-semibold text-sm transition shadow-lg ${
                type === 'BUY'
                  ? 'bg-emerald-500 hover:bg-emerald-400 text-slate-950 shadow-emerald-500/20'
                  : 'bg-red-500 hover:bg-red-400 text-white shadow-red-500/20'
              }`}
            >
              {type === 'BUY' ? 'Alışı Kaydet' : 'Satışı Kaydet'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
