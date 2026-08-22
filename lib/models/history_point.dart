class HistoryPoint {
  final DateTime date;
  final double price;

  HistoryPoint({
    required this.date,
    required this.price,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    try {
      final dateStr = json['date'] as String?;
      final priceVal = json['price'] as num?;
      
      if (dateStr == null || priceVal == null) {
        throw Exception('Missing date or price in history point');
      }
      
      return HistoryPoint(
        date: DateTime.parse(dateStr),
        price: priceVal.toDouble(),
      );
    } catch (e) {
      throw Exception('Error parsing history point: $e');
    }
  }
}
