function formatDate(value) {
  return new Intl.DateTimeFormat('tr-TR', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Europe/Istanbul',
  }).format(value);
}

function formatCurrency(value) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

function formatSignedPercent(value) {
  const sign = value >= 0 ? '+' : '-';
  const absoluteValue = Math.abs(value);
  const formatted = new Intl.NumberFormat('tr-TR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(absoluteValue);
  return `${sign}%${formatted}`;
}

function resolveItemLabel(summaryType, item) {
  if (summaryType === 'fund') {
    return item.name ?? item.code ?? 'Bilinmeyen Fon';
  }
  return item.symbol ?? item.name ?? 'Bilinmeyen Hisse';
}

function normalizeDate(value) {
  if (value instanceof Date) {
    return value;
  }
  if (value && typeof value.toDate === 'function') {
    return value.toDate();
  }
  return new Date(value ?? Date.now());
}

export function buildSummaryEmail({ summaryType, recipientEmail, snapshot }) {
  const isFundSummary = summaryType === 'fund';
  const subject = isFundSummary
    ? '📈 Günlük Fon Özeti'
    : '📊 Günlük Hisse Özeti';
  const lines = [
    `Merhaba,`,
    '',
    isFundSummary
      ? 'Bugunku fon portfoyu ozeti asagidadir:'
      : 'Bugunku hisse portfoyu ozeti asagidadir:',
    '',
  ];

  for (const item of snapshot.items) {
    lines.push(resolveItemLabel(summaryType, item));
    lines.push(formatSignedPercent(Number(item.dailyChangePercent ?? 0)));
    lines.push('');
  }

  lines.push(
    `Toplam Portfoy K/Z: ${formatCurrency(
      Number(snapshot.totalProfitLoss ?? 0),
    )}`,
  );
  lines.push(
    `Portfoy Degeri: ${formatCurrency(
      Number(snapshot.totalPortfolioValue ?? 0),
    )}`,
  );
  lines.push('');
  lines.push(
    `Ozet Zamani: ${formatDate(normalizeDate(snapshot.generatedAt))}`,
  );
  lines.push('');
  lines.push(
    `Bu e-posta FontTakip Bildirimleri tarafindan ${recipientEmail} adresine gonderilmistir.`,
  );

  return {
    subject,
    text: lines.join('\n'),
  };
}
