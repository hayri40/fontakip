import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fund.dart';
import '../models/history_point.dart';

class FonolojiService {
  static const String apiKey =
      'fon_rFKqxTJAur2tAFL_Y_brdrmuahKpVpPX';

  Future<Fund> getFund(String code) async {
    final response = await http.get(
      Uri.parse(
        'https://fonoloji.com/v1/funds/$code',
      ),
      headers: {
        'X-API-Key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final fundData = json['fund'] ?? json;
      return Fund.fromJson(fundData, code);
    } else {
      throw Exception('Failed to load fund: ${response.statusCode}');
    }
  }

  Future<List<HistoryPoint>> getHistory(String code) async {
    final response = await http.get(
      Uri.parse(
        'https://fonoloji.com/v1/funds/$code/history',
      ),
      headers: {
        'X-API-Key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final pointsList = json['points'] as List? ?? [];
      
      final points = pointsList
          .map((item) => HistoryPoint.fromJson(item as Map<String, dynamic>))
          .toList();
      
      points.sort((a, b) => a.date.compareTo(b.date));
      
      // Return last 1 year of data
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      return points.where((p) => p.date.isAfter(oneYearAgo)).toList();
    } else {
      throw Exception('Failed to load history: ${response.statusCode}');
    }
  }
}