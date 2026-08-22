export class AppFormatters {
  static currency(value: number | undefined | null, currencySymbol = '₺'): string {
    if (value === undefined || value === null || isNaN(value)) return `0,00 ${currencySymbol}`;
    
    return `${value.toLocaleString('tr-TR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })} ${currencySymbol}`;
  }

  static signedCurrency(value: number | undefined | null, currencySymbol = '₺'): string {
    if (value === undefined || value === null || isNaN(value)) return `0,00 ${currencySymbol}`;
    const sign = value > 0 ? '+' : value < 0 ? '-' : '';
    const absVal = Math.abs(value);
    
    return `${sign}${absVal.toLocaleString('tr-TR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })} ${currencySymbol}`;
  }

  static percent(value: number | undefined | null): string {
    if (value === undefined || value === null || isNaN(value)) return '%0,00';
    return `%${value.toLocaleString('tr-TR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  static signedPercent(value: number | undefined | null): string {
    if (value === undefined || value === null || isNaN(value)) return '%0,00';
    const sign = value > 0 ? '+' : value < 0 ? '-' : '';
    const absVal = Math.abs(value);
    return `${sign}%${absVal.toLocaleString('tr-TR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  static number(value: number | undefined | null, decimals = 2): string {
    if (value === undefined || value === null || isNaN(value)) return '0';
    return value.toLocaleString('tr-TR', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });
  }

  static date(dateStringOrTimestamp: string | number | Date): string {
    const d = new Date(dateStringOrTimestamp);
    if (isNaN(d.getTime())) return '-';
    return d.toLocaleDateString('tr-TR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  }

  static dateTime(dateStringOrTimestamp: string | number | Date): string {
    const d = new Date(dateStringOrTimestamp);
    if (isNaN(d.getTime())) return '-';
    return d.toLocaleDateString('tr-TR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}
