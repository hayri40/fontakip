class EmailSummaryPreferences {
  final bool fundSummaryEnabled;
  final String fundSummaryTime;
  final DateTime? lastFundSummarySentAt;
  final bool stockSummaryEnabled;
  final String stockSummaryTime;
  final DateTime? lastStockSummarySentAt;

  const EmailSummaryPreferences({
    this.fundSummaryEnabled = false,
    this.fundSummaryTime = '09:30',
    this.lastFundSummarySentAt,
    this.stockSummaryEnabled = false,
    this.stockSummaryTime = '18:30',
    this.lastStockSummarySentAt,
  });

  EmailSummaryPreferences copyWith({
    bool? fundSummaryEnabled,
    String? fundSummaryTime,
    DateTime? lastFundSummarySentAt,
    bool clearLastFundSummarySentAt = false,
    bool? stockSummaryEnabled,
    String? stockSummaryTime,
    DateTime? lastStockSummarySentAt,
    bool clearLastStockSummarySentAt = false,
  }) {
    return EmailSummaryPreferences(
      fundSummaryEnabled: fundSummaryEnabled ?? this.fundSummaryEnabled,
      fundSummaryTime: fundSummaryTime ?? this.fundSummaryTime,
      lastFundSummarySentAt: clearLastFundSummarySentAt
          ? null
          : (lastFundSummarySentAt ?? this.lastFundSummarySentAt),
      stockSummaryEnabled: stockSummaryEnabled ?? this.stockSummaryEnabled,
      stockSummaryTime: stockSummaryTime ?? this.stockSummaryTime,
      lastStockSummarySentAt: clearLastStockSummarySentAt
          ? null
          : (lastStockSummarySentAt ?? this.lastStockSummarySentAt),
    );
  }
}
