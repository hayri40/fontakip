import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat currency = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat decimal = NumberFormat.decimalPattern('tr_TR');
  static final NumberFormat percent = NumberFormat.decimalPattern('tr_TR')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  static String currencyValue(num? value) {
    if (value == null) return '-';
    return currency.format(value);
  }

  static String decimalValue(num? value) {
    if (value == null) return '-';
    return decimal.format(value);
  }

  static String quantityValue(num? value) {
    return decimalValue(value);
  }

  static String quantityLabel(num? value) {
    final formatted = quantityValue(value);
    return '$formatted Adet';
  }

  static String percentValue(num? value) {
    if (value == null) return '-';
    return '%${percent.format(value)}';
  }

  static String signedPercentValue(num? value) {
    if (value == null) return '-';
    final sign = value >= 0 ? '+' : '-';
    return '$sign%${percent.format(value.abs())}';
  }

  static String signedCurrencyValue(num? value) {
    if (value == null) return '-';
    final sign = value >= 0 ? '+' : '-';
    return '$sign${currency.format(value.abs())}';
  }

  static String profitLossLine(num? amount, num? percentValue) {
    if (amount == null || percentValue == null) return '-';
    return '${signedCurrencyValue(amount)} (${percentValue >= 0 ? '%' : '%'}${percent.format(percentValue)})';
  }

  static String priceRange(num? low, num? high) {
    return '${currencyValue(low)} - ${currencyValue(high)}';
  }
}
