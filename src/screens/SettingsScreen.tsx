import React, { useState, useEffect, useRef } from 'react';
import {
  Key,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  Info,
  LogOut,
  Cloud,
  CloudUpload,
  CloudDownload,
  ShieldCheck,
  RefreshCw,
  User as UserIcon,
  FileUp,
  FileCode,
  Check,
  Eye,
  EyeOff,
  Globe,
  Database,
  Layers,
  Sparkles,
} from 'lucide-react';
import { StorageService } from '../services/storage';
import { FirebaseService } from '../services/firebase';
import { MarketDataService } from '../services/marketData';
import { User } from 'firebase/auth';

export const SettingsScreen: React.FC = () => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [syncLoading, setSyncLoading] = useState(false);
  const [syncStatus, setSyncStatus] = useState<string | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);

  // Import state
  const [importJsonText, setImportJsonText] = useState('');
  const [showPasteArea, setShowPasteArea] = useState(false);
  const [importStatus, setImportStatus] = useState<{ success?: boolean; message?: string } | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // Data Sources State
  const [fundProvider, setFundProvider] = useState('https://fonoloji.com/v1/funds');
  const [fundKey, setFundKey] = useState('fon_rFKqxTJAur2tAFL_Y_brdrmuahKpVpPX');
  const [showFundKey, setShowFundKey] = useState(false);
  const [testResultFund, setTestResultFund] = useState<string | null>(null);
  const [testLoadingFund, setTestLoadingFund] = useState(false);

  const [stockApiUrl, setStockApiUrl] = useState('https://api.twelvedata.com/price');
  const [stockKey, setStockKey] = useState('');
  const [showStockKey, setShowStockKey] = useState(false);
  const [stockAppendDotIs, setStockAppendDotIs] = useState(false);
  const [testResultStock, setTestResultStock] = useState<string | null>(null);
  const [testLoadingStock, setTestLoadingStock] = useState(false);

  const [fxProvider, setFxProvider] = useState('https://v6.exchangerate-api.com/v6/');
  const [forexKey, setForexKey] = useState('');
  const [showFxKey, setShowFxKey] = useState(false);
  const [testResultFx, setTestResultFx] = useState<string | null>(null);
  const [testLoadingFx, setTestLoadingFx] = useState(false);

  const [saveSuccess, setSaveSuccess] = useState(false);

  useEffect(() => {
    // Auth state listener
    const unsubscribe = FirebaseService.onAuthStateChanged((user) => {
      setCurrentUser(user);
      setAuthLoading(false);
    });

    loadSettings();

    return () => unsubscribe();
  }, []);

  const loadSettings = () => {
    const s = StorageService.getSettings();
    if (s.fonolojiApiKey) setFundKey(s.fonolojiApiKey);
    if (s.fundProvider) setFundProvider(s.fundProvider);

    if (s.twelveDataApiKey) setStockKey(s.twelveDataApiKey);
    if (s.stockApiUrl) setStockApiUrl(s.stockApiUrl);
    if (s.stockAppendDotIs !== undefined) setStockAppendDotIs(Boolean(s.stockAppendDotIs));

    if (s.exchangeRateApiKey) setForexKey(s.exchangeRateApiKey);
    if (s.fxProvider) setFxProvider(s.fxProvider);
  };

  const handleGoogleSignIn = async () => {
    try {
      setSyncError(null);
      setSyncLoading(true);
      const user = await FirebaseService.signInWithGoogle();
      
      // Auto-fetch data from cloud after sign in
      const cloudData = await FirebaseService.loadUserDataFromCloud(user.uid);
      if (cloudData && (cloudData.fundTransactions?.length || cloudData.stockTransactions?.length)) {
        StorageService.applyCloudData(cloudData);
        setSyncStatus('Buluttaki mevcut portföy verileriniz başarıyla yüklendi.');
        setTimeout(() => window.location.reload(), 1200);
      } else {
        // If no cloud data, upload local data to cloud
        const localData = StorageService.getAllDataForSync();
        await FirebaseService.saveUserDataToCloud(user.uid, localData);
        setSyncStatus('Yerel portföy verileriniz Google hesabınıza başarıyla yedeklendi.');
      }
    } catch (err: any) {
      console.error('Google Sign In error:', err);
      setSyncError(err.message || 'Google ile giriş yapılırken bir hata oluştu.');
    } finally {
      setSyncLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await FirebaseService.signOut();
      setSyncStatus('Oturum kapatıldı.');
    } catch (err: any) {
      setSyncError(err.message || 'Çıkış yapılırken bir hata oluştu.');
    }
  };

  const handleUploadToCloud = async () => {
    if (!currentUser) return;
    try {
      setSyncLoading(true);
      setSyncError(null);
      const localData = StorageService.getAllDataForSync();
      await FirebaseService.saveUserDataToCloud(currentUser.uid, localData);
      setSyncStatus('Mevcut portföyünüz ve ayarlarınız buluta başarıyla kaydedildi.');
      setTimeout(() => setSyncStatus(null), 4000);
    } catch (err: any) {
      setSyncError('Buluta yükleme başarısız: ' + err.message);
    } finally {
      setSyncLoading(false);
    }
  };

  const handleDownloadFromCloud = async () => {
    if (!currentUser) return;
    try {
      setSyncLoading(true);
      setSyncError(null);
      const cloudData = await FirebaseService.loadUserDataFromCloud(currentUser.uid);
      if (cloudData) {
        StorageService.applyCloudData(cloudData);
        setSyncStatus('Bulut verileri ve ayarları başarıyla indirildi. Sayfa yenileniyor...');
        setTimeout(() => window.location.reload(), 1000);
      } else {
        setSyncError('Bulutta kayıtlı veri bulunamadı.');
      }
    } catch (err: any) {
      setSyncError('Buluttan indirme başarısız: ' + err.message);
    } finally {
      setSyncLoading(false);
    }
  };

  const processImportData = async (rawJson: string) => {
    if (!rawJson.trim()) {
      setImportStatus({ success: false, message: 'Lütfen geçerli bir JSON verisi girin.' });
      return;
    }
    const res = StorageService.importRawJsonBackup(rawJson);
    if (res.success) {
      // Reload imported settings
      loadSettings();

      // If user is currently signed in to Google, immediately sync with cloud
      if (currentUser) {
        try {
          const updatedLocalData = StorageService.getAllDataForSync();
          await FirebaseService.saveUserDataToCloud(currentUser.uid, updatedLocalData);
        } catch (e) {
          console.warn('Cloud sync after import failed:', e);
        }
      }

      setImportStatus({
        success: true,
        message: `Yedek, API URL'leri ve anahtarlar başarıyla içe aktarıldı (${res.countInfo}). ${
          currentUser ? 'Google bulutuna otomatik eşitlendi.' : ''
        } Sayfa yenileniyor...`,
      });
      setTimeout(() => {
        window.location.reload();
      }, 1500);
    } else {
      setImportStatus({
        success: false,
        message: `İçe aktarma hatası: ${res.countInfo}`,
      });
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (evt) => {
      const content = evt.target?.result as string;
      if (content) {
        processImportData(content);
      }
    };
    reader.readAsText(file);
  };

  const handleSaveFundSource = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    StorageService.saveApiKeys({
      fonolojiKey: fundKey.trim(),
      fundProvider: fundProvider.trim(),
    });
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  const handleSaveStockSource = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    StorageService.saveApiKeys({
      twelveDataKey: stockKey.trim(),
      stockApiUrl: stockApiUrl.trim(),
      stockAppendDotIs: stockAppendDotIs,
    });
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  const handleSaveFxSource = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    StorageService.saveApiKeys({
      exchangeRateApiKey: forexKey.trim(),
      fxProvider: fxProvider.trim(),
    });
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  const handleSaveAll = (e: React.FormEvent) => {
    e.preventDefault();
    StorageService.saveApiKeys({
      fonolojiKey: fundKey.trim(),
      fundProvider: fundProvider.trim(),
      twelveDataKey: stockKey.trim(),
      stockApiUrl: stockApiUrl.trim(),
      stockAppendDotIs: stockAppendDotIs,
      exchangeRateApiKey: forexKey.trim(),
      fxProvider: fxProvider.trim(),
    });
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  // Live Connection Tests
  const handleTestFund = async () => {
    setTestLoadingFund(true);
    setTestResultFund(null);
    try {
      const res = await MarketDataService.testFundConnection(fundProvider, fundKey);
      setTestResultFund(res);
    } catch (e: any) {
      setTestResultFund(`❌ Hata: ${e.message || 'Servise ulaşılamadı'}`);
    } finally {
      setTestLoadingFund(false);
    }
  };

  const handleTestStock = async () => {
    setTestLoadingStock(true);
    setTestResultStock(null);
    try {
      const res = await MarketDataService.testStockConnection(stockApiUrl, stockKey, stockAppendDotIs);
      setTestResultStock(res);
    } catch (e: any) {
      setTestResultStock(`❌ Hata: ${e.message || 'Servise ulaşılamadı'}`);
    } finally {
      setTestLoadingStock(false);
    }
  };

  const handleTestFx = async () => {
    setTestLoadingFx(true);
    setTestResultFx(null);
    try {
      const res = await MarketDataService.testFxConnection(fxProvider, forexKey);
      setTestResultFx(res);
    } catch (e: any) {
      setTestResultFx(`❌ Hata: ${e.message || 'Servise ulaşılamadı'}`);
    } finally {
      setTestLoadingFx(false);
    }
  };

  const handleResetData = async () => {
    if (
      window.confirm(
        'DİKKAT: Tüm işlemleriniz, borçlarınız, notlarınız ve favorileriniz silinecektir! Emin misiniz?'
      )
    ) {
      StorageService.clearAll();
      if (currentUser) {
        try {
          const emptyData = StorageService.getAllDataForSync();
          await FirebaseService.saveUserDataToCloud(currentUser.uid, emptyData);
        } catch (err) {
          console.warn('Could not reset cloud data:', err);
        }
      }
      window.location.reload();
    }
  };

  return (
    <div className="space-y-6 pb-24 animate-in fade-in duration-200">
      {/* Google Sign-In & Cloud Backup Section */}
      <div className="p-5 sm:p-6 rounded-2xl bg-[#141824] border border-slate-800 space-y-5 shadow-xl">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="p-2.5 rounded-xl bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
              <Cloud className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm sm:text-base font-bold text-white">
                Google Hesabı ile Bulut Senkronizasyonu
              </h3>
              <p className="text-xs text-slate-400 mt-0.5">
                Verileriniz otomatik olarak Google hesabınıza bağlanır ve tüm cihazlarınızda eşitlenir.
              </p>
            </div>
          </div>
        </div>

        {authLoading ? (
          <div className="p-4 text-center text-slate-400 text-xs flex items-center justify-center gap-2">
            <RefreshCw className="w-4 h-4 animate-spin text-cyan-400" />
            Hesap durumu kontrol ediliyor...
          </div>
        ) : currentUser ? (
          /* User is Signed In */
          <div className="space-y-4 pt-1">
            <div className="p-4 rounded-xl bg-[#10131B] border border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="flex items-center gap-3">
                {currentUser.photoURL ? (
                  <img
                    src={currentUser.photoURL}
                    alt={currentUser.displayName || 'Kullanıcı'}
                    className="w-11 h-11 rounded-full border border-cyan-500/40 shadow-sm"
                  />
                ) : (
                  <div className="w-11 h-11 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center border border-cyan-500/30">
                    <UserIcon className="w-5 h-5" />
                  </div>
                )}
                <div>
                  <div className="font-bold text-white text-sm flex items-center gap-1.5">
                    {currentUser.displayName || 'Google Kullanıcısı'}
                    <span className="text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/15 text-emerald-400 border border-emerald-500/20 font-semibold">
                      Bağlı
                    </span>
                  </div>
                  <div className="text-xs text-slate-400">{currentUser.email}</div>
                </div>
              </div>

              <button
                onClick={handleSignOut}
                className="px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold border border-slate-700 transition flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5 text-slate-400" />
                Çıkış Yap
              </button>
            </div>

            {/* Cloud Sync Actions */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                onClick={handleUploadToCloud}
                disabled={syncLoading}
                className="p-3.5 rounded-xl bg-cyan-500/10 hover:bg-cyan-500/20 border border-cyan-500/30 text-cyan-400 font-semibold text-xs transition flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer"
              >
                <CloudUpload className="w-4 h-4" />
                Mevcut Verileri Buluta Kaydet (Yedekle)
              </button>

              <button
                onClick={handleDownloadFromCloud}
                disabled={syncLoading}
                className="p-3.5 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 font-semibold text-xs transition flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer"
              >
                <CloudDownload className="w-4 h-4" />
                Buluttaki Verileri İndir (Eşitle)
              </button>
            </div>
          </div>
        ) : (
          /* User is NOT Signed In */
          <div className="p-5 rounded-xl bg-[#10131B] border border-slate-800 text-center space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 flex items-center justify-center mx-auto">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div className="max-w-md mx-auto space-y-1">
              <h4 className="font-bold text-white text-sm">Google ile Giriş Yapın</h4>
              <p className="text-xs text-slate-400 leading-relaxed">
                Portföyünüzü, fon/hisse işlemlerinizi ve notlarınızı tek tıkla bulutta güvenle saklayın ve cihazlar arası otomatik eşitleyin.
              </p>
            </div>

            <button
              onClick={handleGoogleSignIn}
              disabled={syncLoading}
              className="px-6 py-3 rounded-xl bg-white hover:bg-slate-100 text-slate-900 font-bold text-xs sm:text-sm transition flex items-center justify-center gap-2.5 mx-auto shadow-lg shadow-white/10 disabled:opacity-60 cursor-pointer"
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.17z"
                />
                <path
                  fill="#34A853"
                  d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.4 7.34 24 12 24z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 9.99 0 12s.45 3.82 1.25 5.42l4.03-3.15z"
                />
                <path
                  fill="#EA4335"
                  d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.34 0 3.26 2.6 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
                />
              </svg>
              {syncLoading ? 'Giriş Yapılıyor...' : 'Google ile Giriş Yap'}
            </button>
          </div>
        )}

        {/* Feedback messages */}
        {syncStatus && (
          <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            {syncStatus}
          </div>
        )}

        {syncError && (
          <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            {syncError}
          </div>
        )}
      </div>

      {/* Flutter & Eski Yedek Dosyasını İçe Aktarma Bölümü */}
      <div className="p-5 sm:p-6 rounded-2xl bg-[#141824] border border-slate-800 space-y-4 shadow-xl">
        <div className="flex items-center gap-2.5">
          <div className="p-2.5 rounded-xl bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
            <FileUp className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm sm:text-base font-bold text-white">
              Eski / Flutter Yedek Dosyasını İçe Aktar
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Telefonunuzdaki Flutter uygulamasından aldığınız <span className="text-indigo-300 font-mono">fontakip_backup.json</span> dosyasını seçerek tüm işlemlerinizi, API URL'lerini ve anahtarlarınızı anında buraya taşıyın.
            </p>
          </div>
        </div>

        <input
          type="file"
          accept=".json"
          ref={fileInputRef}
          onChange={handleFileChange}
          className="hidden"
        />

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="p-4 rounded-xl bg-gradient-to-r from-indigo-600/20 to-blue-600/20 hover:from-indigo-600/30 hover:to-blue-600/30 border border-indigo-500/40 text-indigo-300 font-bold text-xs sm:text-sm transition flex items-center justify-center gap-2.5 cursor-pointer shadow-lg shadow-indigo-900/20"
          >
            <FileUp className="w-4 h-4 text-indigo-400" />
            Yedek Dosyası Seç (.json)
          </button>

          <button
            type="button"
            onClick={() => setShowPasteArea(!showPasteArea)}
            className="p-4 rounded-xl bg-[#10131B] hover:bg-slate-800 border border-slate-700 text-slate-300 font-semibold text-xs sm:text-sm transition flex items-center justify-center gap-2 cursor-pointer"
          >
            <FileCode className="w-4 h-4 text-slate-400" />
            {showPasteArea ? 'Metin Alanını Gizle' : 'JSON Metnini Yapıştır'}
          </button>
        </div>

        {showPasteArea && (
          <div className="space-y-3 pt-2 animate-in fade-in">
            <textarea
              rows={4}
              value={importJsonText}
              onChange={(e) => setImportJsonText(e.target.value)}
              placeholder="Yedek JSON içeriğini buraya yapıştırın..."
              className="w-full p-3 bg-[#10131B] border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-indigo-500"
            />
            <button
              onClick={() => processImportData(importJsonText)}
              className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs transition flex items-center gap-2 cursor-pointer shadow-md shadow-indigo-900/30"
            >
              <Check className="w-4 h-4" />
              Yapıştırılan JSON'ı Yükle
            </button>
          </div>
        )}

        {importStatus && (
          <div
            className={`p-3.5 rounded-xl text-xs flex items-center gap-2.5 border ${
              importStatus.success
                ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
                : 'bg-red-500/10 border-red-500/30 text-red-400'
            }`}
          >
            {importStatus.success ? (
              <CheckCircle2 className="w-4 h-4 shrink-0" />
            ) : (
              <AlertTriangle className="w-4 h-4 shrink-0" />
            )}
            <span>{importStatus.message}</span>
          </div>
        )}
      </div>

      {/* VERİ KAYNAKLARI (DATA SOURCES) SECTION - FULL FLUTTER PARITY */}
      <div className="p-5 sm:p-6 rounded-2xl bg-[#141824] border border-slate-800 space-y-6 shadow-xl">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm sm:text-base font-bold text-white">
                Veri Kaynakları & API Yapılandırması
              </h3>
              <p className="text-xs text-slate-400 mt-0.5">
                Canlı piyasa verilerini çekmek için API URL ve anahtarlarınızı yapılandırın.
              </p>
            </div>
          </div>

          <button
            onClick={handleSaveAll}
            className="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold text-xs rounded-xl transition flex items-center justify-center gap-1.5 shadow-md shadow-emerald-500/20 cursor-pointer self-start sm:self-auto"
          >
            <Key className="w-4 h-4" />
            Tüm Kaynakları Kaydet
          </button>
        </div>

        {saveSuccess && (
          <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4" /> Veri kaynakları ve API ayarları başarıyla kaydedildi!
          </div>
        )}

        <div className="space-y-5">
          {/* 1. FON VERİ KAYNAĞI */}
          <div className="p-4 rounded-xl bg-[#10131B] border border-slate-800/80 space-y-3">
            <div className="flex items-center gap-2 text-white font-semibold text-sm">
              <Layers className="w-4 h-4 text-cyan-400" />
              Fon Veri Kaynağı
            </div>

            <div className="space-y-2.5">
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label className="block text-[11px] text-slate-400 font-medium">
                    Sağlayıcı Adı / API URL
                  </label>
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => setFundProvider('https://fonoloji.com/v1/funds')}
                      className="text-[10px] text-cyan-400 hover:underline cursor-pointer"
                    >
                      v1/funds
                    </button>
                    <span className="text-slate-600 text-[10px]">|</span>
                    <button
                      type="button"
                      onClick={() => setFundProvider('https://fonoloji.com')}
                      className="text-[10px] text-cyan-400 hover:underline cursor-pointer"
                    >
                      fonoloji.com
                    </button>
                  </div>
                </div>
                <input
                  type="text"
                  value={fundProvider}
                  onChange={(e) => setFundProvider(e.target.value)}
                  placeholder="https://fonoloji.com/v1/funds veya fonoloji"
                  className="w-full px-3.5 py-2 bg-[#171B26] border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="block text-[11px] text-slate-400 font-medium mb-1">
                  API Anahtarı
                </label>
                <div className="relative">
                  <input
                    type={showFundKey ? 'text' : 'password'}
                    value={fundKey}
                    onChange={(e) => setFundKey(e.target.value)}
                    placeholder="Fon API Anahtarı giriniz..."
                    className="w-full px-3.5 py-2 pr-10 bg-[#171B26] border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-cyan-500"
                  />
                  <button
                    type="button"
                    onClick={() => setShowFundKey(!showFundKey)}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
                  >
                    {showFundKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {testResultFund && (
                <div className={`p-2.5 rounded-lg text-xs font-mono ${testResultFund.includes('✅') ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-red-500/10 text-red-400 border border-red-500/20'}`}>
                  {testResultFund}
                </div>
              )}

              <div className="flex items-center gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => handleSaveFundSource()}
                  className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold border border-slate-700 transition cursor-pointer"
                >
                  Kaydet
                </button>
                <button
                  type="button"
                  onClick={handleTestFund}
                  disabled={testLoadingFund}
                  className="px-3 py-1.5 rounded-lg bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-400 text-xs font-semibold border border-cyan-500/30 transition flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                >
                  {testLoadingFund && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                  Bağlantıyı Test Et
                </button>
              </div>
            </div>
          </div>

          {/* 2. HİSSE VERİ KAYNAĞI (WITH API URL & APPEND .IS CHECKBOX) */}
          <div className="p-4 rounded-xl bg-[#10131B] border border-cyan-500/30 space-y-3 ring-1 ring-cyan-500/20">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-white font-semibold text-sm">
                <Globe className="w-4 h-4 text-emerald-400" />
                Hisse Veri Kaynağı
              </div>
              <span className="text-[10px] px-2 py-0.5 rounded bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 font-bold uppercase">
                BIST / Hisse
              </span>
            </div>

            <div className="space-y-2.5">
              {/* API URL FIELD */}
              <div>
                <label className="block text-[11px] text-slate-300 font-semibold mb-1 flex items-center justify-between">
                  <span>API URL</span>
                  <span className="text-[10px] text-slate-400 font-normal">örn. https://api.twelvedata.com/price</span>
                </label>
                <input
                  type="text"
                  value={stockApiUrl}
                  onChange={(e) => setStockApiUrl(e.target.value)}
                  placeholder="https://api.twelvedata.com/price"
                  className="w-full px-3.5 py-2 bg-[#171B26] border border-cyan-500/40 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-cyan-400 shadow-inner"
                />
              </div>

              {/* API KEY FIELD */}
              <div>
                <label className="block text-[11px] text-slate-300 font-semibold mb-1">
                  API Anahtarı
                </label>
                <div className="relative">
                  <input
                    type={showStockKey ? 'text' : 'password'}
                    value={stockKey}
                    onChange={(e) => setStockKey(e.target.value)}
                    placeholder="Hisse API Anahtarı giriniz (örn: TwelveData API Key)..."
                    className="w-full px-3.5 py-2 pr-10 bg-[#171B26] border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-cyan-500"
                  />
                  <button
                    type="button"
                    onClick={() => setShowStockKey(!showStockKey)}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
                  >
                    {showStockKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* APPEND .IS CHECKBOX */}
              <label className="flex items-center gap-2.5 py-1 text-xs text-slate-300 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={stockAppendDotIs}
                  onChange={(e) => setStockAppendDotIs(e.target.checked)}
                  className="w-4 h-4 rounded bg-[#171B26] border-slate-700 text-cyan-500 focus:ring-cyan-500 cursor-pointer"
                />
                <span>Sembole <strong className="text-cyan-400 font-mono">.IS</strong> ekle (örn: THYAO &rarr; THYAO.IS)</span>
              </label>

              {testResultStock && (
                <div className={`p-2.5 rounded-lg text-xs font-mono ${testResultStock.includes('✅') ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-red-500/10 text-red-400 border border-red-500/20'}`}>
                  {testResultStock}
                </div>
              )}

              <div className="flex items-center gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => handleSaveStockSource()}
                  className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold border border-slate-700 transition cursor-pointer"
                >
                  Kaydet
                </button>
                <button
                  type="button"
                  onClick={handleTestStock}
                  disabled={testLoadingStock}
                  className="px-3 py-1.5 rounded-lg bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 text-xs font-semibold border border-emerald-500/30 transition flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                >
                  {testLoadingStock && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                  Bağlantıyı Test Et
                </button>
              </div>
            </div>
          </div>

          {/* 3. FX / DÖVİZ VERİ KAYNAĞI */}
          <div className="p-4 rounded-xl bg-[#10131B] border border-slate-800/80 space-y-3">
            <div className="flex items-center gap-2 text-white font-semibold text-sm">
              <Sparkles className="w-4 h-4 text-amber-400" />
              FX & Emtia Veri Kaynağı
            </div>

            <div className="space-y-2.5">
              <div>
                <label className="block text-[11px] text-slate-400 font-medium mb-1">
                  Sağlayıcı Adı / API URL
                </label>
                <input
                  type="text"
                  value={fxProvider}
                  onChange={(e) => setFxProvider(e.target.value)}
                  placeholder="https://v6.exchangerate-api.com/v6/ veya ExchangeRate-API"
                  className="w-full px-3.5 py-2 bg-[#171B26] border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="block text-[11px] text-slate-400 font-medium mb-1">
                  API Anahtarı
                </label>
                <div className="relative">
                  <input
                    type={showFxKey ? 'text' : 'password'}
                    value={forexKey}
                    onChange={(e) => setForexKey(e.target.value)}
                    placeholder="FX API Anahtarı giriniz..."
                    className="w-full px-3.5 py-2 pr-10 bg-[#171B26] border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-cyan-500"
                  />
                  <button
                    type="button"
                    onClick={() => setShowFxKey(!showFxKey)}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
                  >
                    {showFxKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {testResultFx && (
                <div className={`p-2.5 rounded-lg text-xs font-mono ${testResultFx.includes('✅') ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-red-500/10 text-red-400 border border-red-500/20'}`}>
                  {testResultFx}
                </div>
              )}

              <div className="flex items-center gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => handleSaveFxSource()}
                  className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold border border-slate-700 transition cursor-pointer"
                >
                  Kaydet
                </button>
                <button
                  type="button"
                  onClick={handleTestFx}
                  disabled={testLoadingFx}
                  className="px-3 py-1.5 rounded-lg bg-amber-500/20 hover:bg-amber-500/30 text-amber-400 text-xs font-semibold border border-amber-500/30 transition flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                >
                  {testLoadingFx && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                  Bağlantıyı Test Et
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Danger Zone: Reset Data */}
      <div className="p-5 rounded-2xl bg-[#1D1418] border border-red-500/30 space-y-3">
        <h3 className="text-sm font-bold text-red-400 uppercase tracking-wider flex items-center gap-2">
          <Trash2 className="w-4 h-4 text-red-400" />
          Tehlikeli Bölge
        </h3>
        <p className="text-xs text-slate-300">
          Yerel tarayıcıdaki tüm verileri silerek uygulamayı ilk açılış durumuna sıfırlar.
        </p>
        <button
          onClick={handleResetData}
          className="px-4 py-2.5 rounded-xl bg-red-600 hover:bg-red-500 text-white font-bold text-xs transition shadow-md shadow-red-900/30 cursor-pointer"
        >
          Yerel Verileri ve Portföyü Sıfırla
        </button>
      </div>

      {/* App Info */}
      <div className="p-5 rounded-2xl bg-[#141824] border border-slate-800 space-y-2 text-xs text-slate-400">
        <div className="flex items-center gap-2 text-white font-bold">
          <Info className="w-4 h-4 text-cyan-400" />
          FonTakip Web v1.2.0
        </div>
        <p>
          TEFAS Yatırım Fonları, Borsa İstanbul (BIST), Canlı FX & Emtia Piyasaları Takip ve Portföy Yönetim Platformu.
        </p>
      </div>
    </div>
  );
};

