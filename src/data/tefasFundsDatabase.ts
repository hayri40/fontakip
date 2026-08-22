export interface TefasFundInfo {
  code: string;
  name: string;
  category: string;
  managementCompany: string;
  currentPrice: number;
  return1Y: number;
  realReturn1Y: number;
  riskScore: number;
  sharpe90: number;
}

export const TEFAS_FUNDS_CATALOG: TefasFundInfo[] = [
  // --- KUVEYT TÜRK & KATILIM FONLARI ---
  { code: 'KLU', name: 'Kuveyt Türk Portföy Para Piyasası Katılım (TL) Fonu', category: 'Para Piyasası Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 4.8377, return1Y: 52.4, realReturn1Y: 14.2, riskScore: 1, sharpe90: 2.45 },
  { code: 'KZL', name: 'Kuveyt Türk Portföy Altın Katılım Fonu', category: 'Kıymetli Madenler Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 0.2450, return1Y: 73.4, realReturn1Y: 17.1, riskScore: 6, sharpe90: 2.10 },
  { code: 'KTK', name: 'Kuveyt Türk Portföy Kısa Vadeli Kira Sertifikaları Katılım Fonu', category: 'Kira Sertifikası Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 2.3410, return1Y: 48.9, realReturn1Y: 11.2, riskScore: 2, sharpe90: 2.15 },
  { code: 'KTS', name: 'Kuveyt Türk Portföy Katılım Hisse Senedi Fonu (Hisse Yoğun)', category: 'Hisse Senedi Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 7.8920, return1Y: 84.5, realReturn1Y: 26.3, riskScore: 6, sharpe90: 2.35 },
  { code: 'KPV', name: 'Kuveyt Türk Portföy Birinci Değişken Katılım Fonu', category: 'Değişken Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 3.4560, return1Y: 65.2, realReturn1Y: 16.8, riskScore: 4, sharpe90: 1.95 },
  { code: 'KPD', name: 'Kuveyt Türk Portföy İkinci Değişken Katılım Fonu', category: 'Değişken Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 2.8940, return1Y: 69.4, realReturn1Y: 18.5, riskScore: 5, sharpe90: 2.05 },
  { code: 'KPG', name: 'Kuveyt Türk Portföy Gümüş Katılım Fonu', category: 'Kıymetli Madenler Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 0.1420, return1Y: 78.9, realReturn1Y: 21.4, riskScore: 7, sharpe90: 1.85 },
  { code: 'KSU', name: 'Kuveyt Türk Portföy Sürdürülebilirlik Katılım Fonu', category: 'Katılım Fonu', managementCompany: 'Kuveyt Türk Portföy', currentPrice: 1.9540, return1Y: 61.2, realReturn1Y: 13.5, riskScore: 5, sharpe90: 1.75 },

  // --- İŞ PORTFÖY ---
  { code: 'TI1', name: 'İş Portföy Para Piyasası (TL) Fonu', category: 'Para Piyasası Fonu', managementCompany: 'İş Portföy', currentPrice: 1665.8766, return1Y: 53.8, realReturn1Y: 15.1, riskScore: 1, sharpe90: 2.65 },
  { code: 'TI2', name: 'İş Portföy İkinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'İş Portföy', currentPrice: 4.1205, return1Y: 68.3, realReturn1Y: 12.4, riskScore: 5, sharpe90: 1.95 },
  { code: 'TI3', name: 'İş Portföy Üçüncü Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'İş Portföy', currentPrice: 5.6420, return1Y: 72.4, realReturn1Y: 15.8, riskScore: 5, sharpe90: 2.10 },
  { code: 'TTE', name: 'İş Portföy BIST Teknoloji Ağırlık Sınırlamalı Hisse Senedi Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'İş Portföy', currentPrice: 1.7678, return1Y: 92.4, realReturn1Y: 34.6, riskScore: 7, sharpe90: 2.84 },
  { code: 'TAU', name: 'İş Portföy BIST Banka Endeksi Hisse Senedi Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'İş Portföy', currentPrice: 6.8420, return1Y: 115.4, realReturn1Y: 48.2, riskScore: 7, sharpe90: 3.10 },
  { code: 'IDH', name: 'İş Portföy BIST 100 Dışı Şirketler Hisse Senedi Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'İş Portföy', currentPrice: 12.4500, return1Y: 89.2, realReturn1Y: 29.5, riskScore: 6, sharpe90: 2.40 },
  { code: 'TTA', name: 'İş Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'İş Portföy', currentPrice: 0.1780, return1Y: 71.8, realReturn1Y: 16.2, riskScore: 6, sharpe90: 2.05 },
  { code: 'TGE', name: 'İş Portföy Emtia Yabancı BYF Fon Sepeti Fonu', category: 'Fon Sepeti Fonu', managementCompany: 'İş Portföy', currentPrice: 0.4520, return1Y: 58.6, realReturn1Y: 9.4, riskScore: 5, sharpe90: 1.65 },
  { code: 'TFF', name: 'İş Portföy Eurobond (Borçlanma Araçları) Fonu', category: 'Borçlanma Araçları Fonu', managementCompany: 'İş Portföy', currentPrice: 0.0890, return1Y: 44.5, realReturn1Y: 5.2, riskScore: 4, sharpe90: 1.45 },
  { code: 'TP2', name: 'İş Portföy Birinci Serbest (TL) Fon', category: 'Serbest Fon', managementCompany: 'İş Portföy', currentPrice: 32.4500, return1Y: 58.2, realReturn1Y: 14.1, riskScore: 4, sharpe90: 2.20 },

  // --- AK PORTFÖY ---
  { code: 'AFT', name: 'Ak Portföy Yeni Teknolojiler Yabancı Hisse Senedi Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.3845, return1Y: 88.6, realReturn1Y: 30.1, riskScore: 6, sharpe90: 2.50 },
  { code: 'AFS', name: 'Ak Portföy Sağlık Sektörü Yabancı Hisse Senedi Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.2980, return1Y: 62.4, realReturn1Y: 13.8, riskScore: 6, sharpe90: 1.85 },
  { code: 'AFV', name: 'Ak Portföy Avrupa Yabancı Hisse Senedi Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.1850, return1Y: 55.4, realReturn1Y: 8.9, riskScore: 5, sharpe90: 1.60 },
  { code: 'AKU', name: 'Ak Portföy Para Piyasası (TL) Fonu', category: 'Para Piyasası Fonu', managementCompany: 'Ak Portföy', currentPrice: 3.4250, return1Y: 53.1, realReturn1Y: 14.8, riskScore: 1, sharpe90: 2.55 },
  { code: 'ALC', name: 'Ak Portföy İhracatçı Şirketler Hisse Senedi Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 4.8900, return1Y: 76.5, realReturn1Y: 19.8, riskScore: 6, sharpe90: 2.15 },
  { code: 'AFA', name: 'Ak Portföy Amerika Yabancı Hisse Senedi Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.4120, return1Y: 82.3, realReturn1Y: 24.5, riskScore: 6, sharpe90: 2.30 },
  { code: 'AFO', name: 'Ak Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.2150, return1Y: 72.5, realReturn1Y: 16.7, riskScore: 6, sharpe90: 2.08 },
  { code: 'AK3', name: 'Ak Portföy BIST 30 Endeksi Hisse Senedi Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 2.7600, return1Y: 81.4, realReturn1Y: 22.8, riskScore: 6, sharpe90: 2.25 },
  { code: 'BIO', name: 'Ak Portföy Biyoteknoloji Sektörü Yabancı Hisse Senedi Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.1650, return1Y: 59.8, realReturn1Y: 11.2, riskScore: 6, sharpe90: 1.70 },
  { code: 'ZPE', name: 'Ak Portföy Fintek ve Blokzinciri Teknolojileri Yabancı Hisse Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Ak Portföy', currentPrice: 0.2240, return1Y: 94.2, realReturn1Y: 35.1, riskScore: 7, sharpe90: 2.60 },

  // --- GARANTİ BBVA PORTFÖY ---
  { code: 'GTA', name: 'Garanti Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Garanti Portföy', currentPrice: 0.1824, return1Y: 72.1, realReturn1Y: 16.3, riskScore: 6, sharpe90: 2.05 },
  { code: 'GTL', name: 'Garanti Portföy Para Piyasası (TL) Fonu', category: 'Para Piyasası Fonu', managementCompany: 'Garanti Portföy', currentPrice: 2.8940, return1Y: 53.6, realReturn1Y: 15.0, riskScore: 1, sharpe90: 2.60 },
  { code: 'GAE', name: 'Garanti Portföy Hisse Senedi Fonu (Hisse Yoğun)', category: 'Hisse Senedi Fonu', managementCompany: 'Garanti Portföy', currentPrice: 8.4500, return1Y: 83.2, realReturn1Y: 24.8, riskScore: 6, sharpe90: 2.30 },
  { code: 'GBG', name: 'Garanti Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Garanti Portföy', currentPrice: 3.1200, return1Y: 67.8, realReturn1Y: 13.5, riskScore: 4, sharpe90: 1.90 },
  { code: 'GMR', name: 'Inveo Portföy İkinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Inveo Portföy', currentPrice: 3.1240, return1Y: 71.4, realReturn1Y: 15.2, riskScore: 5, sharpe90: 1.88 },
  { code: 'GZY', name: 'Garanti Portföy Sürdürülebilirlik Fon Sepeti Fonu', category: 'Fon Sepeti Fonu', managementCompany: 'Garanti Portföy', currentPrice: 1.4500, return1Y: 64.2, realReturn1Y: 12.1, riskScore: 5, sharpe90: 1.80 },
  { code: 'GUM', name: 'Garanti Portföy Gümüş Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Garanti Portföy', currentPrice: 0.1280, return1Y: 81.2, realReturn1Y: 22.6, riskScore: 7, sharpe90: 1.90 },

  // --- YAPI KREDİ PORTFÖY ---
  { code: 'YAY', name: 'Yapı Kredi Portföy Yabancı Teknoloji Sektörü Hisse Senedi Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Yapı Kredi Portföy', currentPrice: 2.4560, return1Y: 85.1, realReturn1Y: 27.8, riskScore: 6, sharpe90: 2.38 },
  { code: 'YAC', name: 'Yapı Kredi Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Yapı Kredi Portföy', currentPrice: 0.1654, return1Y: 71.9, realReturn1Y: 16.0, riskScore: 6, sharpe90: 2.02 },
  { code: 'YAS', name: 'Yapı Kredi Portföy Koç Holding İştirakleri Hisse Senedi Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'Yapı Kredi Portföy', currentPrice: 18.7500, return1Y: 96.8, realReturn1Y: 37.2, riskScore: 6, sharpe90: 2.75 },
  { code: 'YTD', name: 'Yapı Kredi Portföy İkinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Yapı Kredi Portföy', currentPrice: 4.8200, return1Y: 74.2, realReturn1Y: 17.5, riskScore: 5, sharpe90: 2.10 },
  { code: 'YLY', name: 'Yapı Kredi Portföy Para Piyasası (TL) Fonu', category: 'Para Piyasası Fonu', managementCompany: 'Yapı Kredi Portföy', currentPrice: 5.4100, return1Y: 53.4, realReturn1Y: 14.9, riskScore: 1, sharpe90: 2.58 },

  // --- TACİRLER & MARMARA & HEDEF & İSTANBUL PORTFÖY ---
  { code: 'MAC', name: 'Marmara Capital Portföy Hisse Senedi (TL) Fonu (Hisse Yoğun)', category: 'Hisse Senedi Şemsiye Fonu', managementCompany: 'Marmara Capital', currentPrice: 0.7579, return1Y: 81.2, realReturn1Y: 23.5, riskScore: 6, sharpe90: 2.45 },
  { code: 'TCD', name: 'Tacirler Portföy Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Tacirler Portföy', currentPrice: 14.8520, return1Y: 96.3, realReturn1Y: 37.5, riskScore: 7, sharpe90: 2.92 },
  { code: 'TKF', name: 'Tacirler Portföy Hisse Senedi Fonu (Hisse Yoğun)', category: 'Hisse Senedi Fonu', managementCompany: 'Tacirler Portföy', currentPrice: 22.4100, return1Y: 91.5, realReturn1Y: 33.2, riskScore: 7, sharpe90: 2.65 },
  { code: 'IPB', name: 'İstanbul Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'İstanbul Portföy', currentPrice: 6.8240, return1Y: 79.5, realReturn1Y: 21.9, riskScore: 6, sharpe90: 2.20 },
  { code: 'IHK', name: 'İstanbul Portföy Hisse Senedi Fonu (Hisse Yoğun)', category: 'Hisse Senedi Fonu', managementCompany: 'İstanbul Portföy', currentPrice: 11.2300, return1Y: 88.4, realReturn1Y: 28.9, riskScore: 6, sharpe90: 2.40 },
  { code: 'NNF', name: 'Hedef Portföy Birinci Hisse Senedi Fonu (Hisse Yoğun)', category: 'Hisse Senedi Fonu', managementCompany: 'Hedef Portföy', currentPrice: 4.9500, return1Y: 87.6, realReturn1Y: 28.1, riskScore: 6, sharpe90: 2.35 },
  { code: 'HVT', name: 'Hedef Portföy İkinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Hedef Portföy', currentPrice: 3.8400, return1Y: 73.1, realReturn1Y: 16.4, riskScore: 5, sharpe90: 2.00 },
  { code: 'NRC', name: 'Nurol Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Nurol Portföy', currentPrice: 2.9400, return1Y: 69.8, realReturn1Y: 14.5, riskScore: 5, sharpe90: 1.95 },
  { code: 'TLY', name: 'Tera Portföy Birinci Serbest Fon', category: 'Serbest Fon', managementCompany: 'Tera Portföy', currentPrice: 8865.3297, return1Y: 120.5, realReturn1Y: 55.4, riskScore: 7, sharpe90: 3.20 },
  { code: 'VGA', name: 'Türkiye Hayat Emeklilik Altın Katılım Fonu', category: 'Altın Katılım Fonu', managementCompany: 'Türkiye Emeklilik', currentPrice: 0.7857, return1Y: 72.8, realReturn1Y: 16.9, riskScore: 6, sharpe90: 2.12 },

  // --- TEB & ZİRAAT & HALK & QNB ---
  { code: 'ZPE', name: 'Ziraat Portföy Katılım Fonu', category: 'Katılım Fonu', managementCompany: 'Ziraat Portföy', currentPrice: 1.8450, return1Y: 58.4, realReturn1Y: 11.5, riskScore: 3, sharpe90: 1.80 },
  { code: 'ZPF', name: 'Ziraat Portföy Para Piyasası Fonu', category: 'Para Piyasası Fonu', managementCompany: 'Ziraat Portföy', currentPrice: 3.1200, return1Y: 53.2, realReturn1Y: 14.7, riskScore: 1, sharpe90: 2.50 },
  { code: 'ZEL', name: 'Ziraat Portföy BIST 30 Dışı Şirketler Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'Ziraat Portföy', currentPrice: 5.6200, return1Y: 86.4, realReturn1Y: 27.2, riskScore: 6, sharpe90: 2.30 },
  { code: 'HPT', name: 'Halk Portföy Para Piyasası Fonu', category: 'Para Piyasası Fonu', managementCompany: 'Halk Portföy', currentPrice: 2.7600, return1Y: 53.0, realReturn1Y: 14.6, riskScore: 1, sharpe90: 2.48 },
  { code: 'TDB', name: 'TEB Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'TEB Portföy', currentPrice: 4.1500, return1Y: 70.5, realReturn1Y: 15.3, riskScore: 5, sharpe90: 2.05 },
  { code: 'TOT', name: 'TEB Portföy Para Piyasası Fonu', category: 'Para Piyasası Fonu', managementCompany: 'TEB Portföy', currentPrice: 6.2400, return1Y: 53.5, realReturn1Y: 14.9, riskScore: 1, sharpe90: 2.55 },
  { code: 'DBH', name: 'Deniz Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Deniz Portföy', currentPrice: 3.8200, return1Y: 69.4, realReturn1Y: 14.8, riskScore: 5, sharpe90: 1.98 },
  { code: 'QNB', name: 'QNB Portföy Para Piyasası Fonu', category: 'Para Piyasası Fonu', managementCompany: 'QNB Portföy', currentPrice: 4.3100, return1Y: 53.3, realReturn1Y: 14.8, riskScore: 1, sharpe90: 2.52 },
  { code: 'FIB', name: 'Fiba Portföy Çoklu Varlık Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Fiba Portföy', currentPrice: 2.9800, return1Y: 66.8, realReturn1Y: 13.0, riskScore: 4, sharpe90: 1.85 },
  { code: 'OJT', name: 'QNB Portföy İkinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'QNB Portföy', currentPrice: 5.1200, return1Y: 73.6, realReturn1Y: 17.2, riskScore: 5, sharpe90: 2.12 },
  { code: 'CPH', name: 'Colendi Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Colendi Portföy', currentPrice: 1.4500, return1Y: 71.0, realReturn1Y: 15.5, riskScore: 5, sharpe90: 1.92 },
  { code: 'GTD', name: 'Garanti Portföy Kısa Vadeli Borçlanma Fonu', category: 'Borçlanma Araçları Fonu', managementCompany: 'Garanti Portföy', currentPrice: 2.1500, return1Y: 51.2, realReturn1Y: 13.1, riskScore: 2, sharpe90: 2.30 },
  { code: 'AMZ', name: 'Atlas Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Atlas Portföy', currentPrice: 3.6400, return1Y: 75.8, realReturn1Y: 18.6, riskScore: 5, sharpe90: 2.15 },
  { code: 'EUZ', name: 'Euro Yatırım Portföy Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Euro Portföy', currentPrice: 2.1800, return1Y: 64.5, realReturn1Y: 11.8, riskScore: 4, sharpe90: 1.75 },
  { code: 'DCB', name: 'Deniz Portföy Çoklu Varlık Fonu', category: 'Değişken Şemsiye Fonu', managementCompany: 'Deniz Portföy', currentPrice: 4.7500, return1Y: 72.0, realReturn1Y: 16.0, riskScore: 5, sharpe90: 2.05 },
  { code: 'FPZ', name: 'Fiba Portföy Serbest Fon', category: 'Serbest Fon', managementCompany: 'Fiba Portföy', currentPrice: 12.8000, return1Y: 82.4, realReturn1Y: 24.5, riskScore: 6, sharpe90: 2.25 },
  { code: 'PUR', name: 'Pardus Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Pardus Portföy', currentPrice: 2.4500, return1Y: 68.9, realReturn1Y: 14.1, riskScore: 5, sharpe90: 1.90 },
  { code: 'GHA', name: 'Gedik Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Gedik Portföy', currentPrice: 3.8900, return1Y: 74.5, realReturn1Y: 17.8, riskScore: 5, sharpe90: 2.10 },
  { code: 'GAL', name: 'Gedik Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Gedik Portföy', currentPrice: 0.1740, return1Y: 71.5, realReturn1Y: 15.9, riskScore: 6, sharpe90: 2.01 },
  { code: 'YTY', name: 'Yapı Kredi Portföy BIST 100 Fonu', category: 'Hisse Senedi Fonu', managementCompany: 'Yapı Kredi Portföy', currentPrice: 6.7800, return1Y: 82.6, realReturn1Y: 24.0, riskScore: 6, sharpe90: 2.28 },
  { code: 'DAS', name: 'Deniz Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Deniz Portföy', currentPrice: 0.1690, return1Y: 71.8, realReturn1Y: 16.1, riskScore: 6, sharpe90: 2.03 },
  { code: 'GRO', name: 'Garanti Portföy Yabancı Teknoloji Fonu', category: 'Yabancı Hisse Senedi Fonu', managementCompany: 'Garanti Portföy', currentPrice: 1.8400, return1Y: 86.4, realReturn1Y: 28.5, riskScore: 6, sharpe90: 2.42 },
  { code: 'GEV', name: 'Garanti Portföy Eurobond Fonu', category: 'Borçlanma Araçları Fonu', managementCompany: 'Garanti Portföy', currentPrice: 0.0940, return1Y: 45.1, realReturn1Y: 5.8, riskScore: 4, sharpe90: 1.50 },
  { code: 'ILH', name: 'İş Portföy Katılım Hisse Senedi Fonu', category: 'Hisse Senedi Katılım Fonu', managementCompany: 'İş Portföy', currentPrice: 5.4200, return1Y: 85.0, realReturn1Y: 26.8, riskScore: 6, sharpe90: 2.38 },
  { code: 'ONS', name: 'Neo Portföy Birinci Değişken Fon', category: 'Değişken Şemsiye Fonu', managementCompany: 'Neo Portföy', currentPrice: 3.1500, return1Y: 70.2, realReturn1Y: 15.1, riskScore: 5, sharpe90: 1.96 },
  { code: 'PAL', name: 'Pardus Portföy Altın Fonu', category: 'Kıymetli Madenler Fonu', managementCompany: 'Pardus Portföy', currentPrice: 0.1710, return1Y: 71.6, realReturn1Y: 16.0, riskScore: 6, sharpe90: 2.02 },
  { code: 'YP4', name: 'Yapı Kredi Portföy Özel Bankacılık Serbest Fon', category: 'Serbest Fon', managementCompany: 'Yapı Kredi Portföy', currentPrice: 45.2000, return1Y: 62.4, realReturn1Y: 17.5, riskScore: 4, sharpe90: 2.30 },
];
