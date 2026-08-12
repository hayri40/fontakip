import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters/app_formatters.dart';
import '../models/holding.dart';
import '../models/stock_holding.dart';
import '../services/portfolio_service.dart';
import '../services/stock_portfolio_service.dart';

class PerformanceTrackingScreen extends StatefulWidget {
  final PortfolioService? portfolioService;
  final StockPortfolioService? stockPortfolioService;
  final DateTime Function()? nowProvider;

  const PerformanceTrackingScreen({
    super.key,
    this.portfolioService,
    this.stockPortfolioService,
    this.nowProvider,
  });

  @override
  State<PerformanceTrackingScreen> createState() =>
      _PerformanceTrackingScreenState();
}

class _PerformanceTrackingScreenState extends State<PerformanceTrackingScreen> {
  static const _targetGrowthKey = 'performance.targetGrowth';
  static const _recordsKey = 'performance.records';

  final _targetGrowthController = TextEditingController();
  final List<_PerformanceRecord> _records = [];

  late final PortfolioService _portfolioService;
  late final StockPortfolioService _stockPortfolioService;
  SharedPreferences? _prefs;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _portfolioService = widget.portfolioService ?? PortfolioService();
    _stockPortfolioService =
        widget.stockPortfolioService ?? StockPortfolioService();
    _targetGrowthController.addListener(_onChanged);
    _loadPrefs();
  }

  @override
  void dispose() {
    _targetGrowthController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    _targetGrowthController.text = prefs.getString(_targetGrowthKey) ?? '';
    final savedRecords = prefs.getString(_recordsKey);
    if (savedRecords != null) {
      final decoded = jsonDecode(savedRecords) as List<dynamic>;
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        _records.add(
          _PerformanceRecord(
            date: DateTime.parse(map['date'] as String),
            portfolioValue: (map['portfolioValue'] as num).toDouble(),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  void _onChanged() {
    if (!_ready || !mounted) return;
    setState(() {});
    _savePrefs();
  }

  Future<void> _savePrefs() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_targetGrowthKey, _targetGrowthController.text);
    await prefs.setString(
      _recordsKey,
      jsonEncode(
        _records
            .map(
              (record) => {
                'date': record.date.toIso8601String(),
                'portfolioValue': record.portfolioValue,
              },
            )
            .toList(),
      ),
    );
  }

  double _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  Future<void> _addRecord() async {
    try {
      final fundHoldings = await _portfolioService.getHoldings();
      final stockHoldings = await _stockPortfolioService.getHoldings();
      final totalValue = _calculateTotalPortfolioValue(fundHoldings, stockHoldings);
      final now = widget.nowProvider?.call() ?? DateTime.now();

      setState(() {
        _records.add(
          _PerformanceRecord(
            date: DateTime(now.year, now.month, now.day),
            portfolioValue: totalValue,
          ),
        );
      });
      _savePrefs();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portföy bilgileri şu anda yüklenemedi.'),
        ),
      );
    }
  }

  double _calculateTotalPortfolioValue(
    List<Holding> fundHoldings,
    List<StockHolding> stockHoldings,
  ) {
    final fundTotal = fundHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    final stockTotal = stockHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    return fundTotal + stockTotal;
  }

  Future<void> _confirmDeleteLast() async {
    if (_records.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Son Kaydı Sil'),
          content: const Text(
            'En son performans kaydı silinecek.\n\n'
            'Bu işlem geri alınamaz.\n\n'
            'Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _records.removeLast();
    });
    _savePrefs();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final targetGrowth = _parse(_targetGrowthController.text);
    final rows = _buildRows(targetGrowth);

    final comparableRows = rows.where((row) => row.actualGrowth != null).toList();
    final aboveCount = comparableRows.where((row) => row.diff! > 0).length;
    final belowCount = comparableRows.where((row) => row.diff! < 0).length;
    final averageGrowth = comparableRows.isEmpty
        ? 0.0
        : comparableRows.fold<double>(0.0, (sum, row) => sum + row.actualGrowth!) /
            comparableRows.length;
    final targetCompound = comparableRows.isEmpty
        ? 0.0
        : (pow(1 + (targetGrowth / 100), comparableRows.length).toDouble() - 1) *
            100;
    final realizedCompound = _records.length < 2 || _records.first.portfolioValue == 0
        ? 0.0
        : ((_records.last.portfolioValue / _records.first.portfolioValue) - 1) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performans Takibi'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF1A1D24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _targetGrowthController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Hedef Büyüme %',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addRecord,
                          icon: const Icon(Icons.add),
                          label: const Text('➕ Yeni Kayıt'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _records.isEmpty ? null : _confirmDeleteLast,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('🗑 Son Kaydı Sil'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1A1D24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Tarih')),
                    DataColumn(label: Text('Portföy')),
                    DataColumn(label: Text('Gerçek')),
                    DataColumn(label: Text('Hedef')),
                    DataColumn(label: Text('Fark')),
                  ],
                  rows: rows.map((row) {
                    final diffColor = row.diff == null
                        ? Colors.grey[400]
                        : row.diff! >= 0
                            ? Colors.green
                            : Colors.red;
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatDate(row.record.date))),
                        DataCell(Text(AppFormatters.currencyValue(row.record.portfolioValue))),
                        DataCell(
                          Text(
                            row.actualGrowth == null
                                ? '-'
                                : AppFormatters.percentValue(row.actualGrowth),
                          ),
                        ),
                        DataCell(Text(AppFormatters.percentValue(targetGrowth))),
                        DataCell(
                          Text(
                            row.diff == null
                                ? '-'
                                : AppFormatters.signedPercentValue(row.diff),
                            style: TextStyle(
                              color: diffColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1A1D24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel İstatistikler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _statRow('Kayıt Sayısı', '${_records.length}'),
                  _statRow('Hedef Üstü Kayıt', '$aboveCount'),
                  _statRow('Hedef Altı Kayıt', '$belowCount'),
                  _statRow('Ortalama Büyüme', AppFormatters.percentValue(averageGrowth)),
                  _statRow(
                    'Toplam Hedef Bileşik Getiri',
                    AppFormatters.percentValue(targetCompound),
                  ),
                  _statRow(
                    'Toplam Gerçekleşen Bileşik Getiri',
                    AppFormatters.percentValue(realizedCompound),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_PerformanceTableRow> _buildRows(double targetGrowth) {
    final rows = <_PerformanceTableRow>[];
    for (var i = 0; i < _records.length; i++) {
      if (i == 0) {
        rows.add(
          _PerformanceTableRow(
            record: _records[i],
            actualGrowth: null,
            diff: null,
          ),
        );
        continue;
      }

      final previous = _records[i - 1].portfolioValue;
      final current = _records[i].portfolioValue;
      final actualGrowth = previous == 0 ? 0.0 : ((current - previous) / previous) * 100;
      rows.add(
        _PerformanceTableRow(
          record: _records[i],
          actualGrowth: actualGrowth,
          diff: actualGrowth - targetGrowth,
        ),
      );
    }
    return rows;
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRecord {
  final DateTime date;
  final double portfolioValue;

  _PerformanceRecord({
    required this.date,
    required this.portfolioValue,
  });
}

class _PerformanceTableRow {
  final _PerformanceRecord record;
  final double? actualGrowth;
  final double? diff;

  _PerformanceTableRow({
    required this.record,
    required this.actualGrowth,
    required this.diff,
  });
}
