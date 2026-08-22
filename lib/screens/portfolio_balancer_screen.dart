import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters/app_formatters.dart';
import '../models/holding.dart';
import '../models/stock_holding.dart';
import '../services/portfolio_service.dart';
import '../services/stock_portfolio_service.dart';

class PortfolioBalancerScreen extends StatefulWidget {
  final PortfolioService? portfolioService;
  final StockPortfolioService? stockPortfolioService;

  const PortfolioBalancerScreen({
    super.key,
    this.portfolioService,
    this.stockPortfolioService,
  });

  @override
  State<PortfolioBalancerScreen> createState() =>
      _PortfolioBalancerScreenState();
}

class _PortfolioBalancerScreenState extends State<PortfolioBalancerScreen> {
  static const _generalBudgetKey = 'balancer.general.budget';
  static const _generalFundKey = 'balancer.general.fund';
  static const _generalStockKey = 'balancer.general.stock';
  static const _generalFxKey = 'balancer.general.fx';
  static const _fundBudgetKey = 'balancer.fund.budget';
  static const _fundRowsKey = 'balancer.fund.rows';

  late final PortfolioService _portfolioService;
  late final StockPortfolioService _stockPortfolioService;

  final _generalBudgetController = TextEditingController();
  final _generalFundController = TextEditingController();
  final _generalStockController = TextEditingController();
  final _generalFxController = TextEditingController();
  final _fundBudgetController = TextEditingController();
  final List<_FundSimulationRow> _fundRows = [];

  SharedPreferences? _prefs;
  List<Holding> _fundHoldings = [];
  List<StockHolding> _stockHoldings = [];
  bool _loading = true;
  bool _ready = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _portfolioService = widget.portfolioService ?? PortfolioService();
    _stockPortfolioService =
        widget.stockPortfolioService ?? StockPortfolioService();
    _generalBudgetController.addListener(_onChanged);
    _generalFundController.addListener(_onChanged);
    _generalStockController.addListener(_onChanged);
    _generalFxController.addListener(_onChanged);
    _fundBudgetController.addListener(_onChanged);
    _loadData();
  }

  @override
  void dispose() {
    _generalBudgetController.dispose();
    _generalFundController.dispose();
    _generalStockController.dispose();
    _generalFxController.dispose();
    _fundBudgetController.dispose();
    for (final row in _fundRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _ready = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      List<Holding> fundHoldings = [];
      List<StockHolding> stockHoldings = [];
      String? loadError;

      try {
        fundHoldings = await _portfolioService.getHoldings();
      } catch (_) {
        loadError = 'Portföy bilgileri şu anda yüklenemedi.';
      }

      try {
        stockHoldings = await _stockPortfolioService.getHoldings();
      } catch (_) {
        loadError = 'Portföy bilgileri şu anda yüklenemedi.';
      }

      if (!mounted) return;

      _fundHoldings = fundHoldings;
      _stockHoldings = stockHoldings;
      _restoreControllers(prefs);
      _restoreFundRows(prefs);

      setState(() {
        _errorMessage = loadError;
        _loading = false;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Portföy bilgileri şu anda yüklenemedi.';
        _loading = false;
      });
    }
  }

  void _restoreControllers(SharedPreferences prefs) {
    _generalBudgetController.text = prefs.getString(_generalBudgetKey) ?? '';
    _generalFundController.text = prefs.getString(_generalFundKey) ?? '';
    _generalStockController.text = prefs.getString(_generalStockKey) ?? '';
    _generalFxController.text = prefs.getString(_generalFxKey) ?? '';
    _fundBudgetController.text = prefs.getString(_fundBudgetKey) ?? '';
  }

  void _restoreFundRows(SharedPreferences prefs) {
    for (final row in _fundRows) {
      row.dispose();
    }
    _fundRows.clear();

    final savedRows = prefs.getString(_fundRowsKey);
    if (savedRows != null) {
      final decoded = jsonDecode(savedRows) as List<dynamic>;
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        final row = _FundSimulationRow(
          code: map['code']?.toString() ?? '',
          percent: map['percent']?.toString() ?? '',
        );
        row.codeController.addListener(_onChanged);
        row.percentController.addListener(_onChanged);
        _fundRows.add(row);
      }
      return;
    }

    final fundTotal = _fundHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    for (final holding in _fundHoldings) {
      final row = _FundSimulationRow(
        code: holding.fundCode,
        percent: _defaultPercentText(holding.currentValue, fundTotal),
      );
      row.codeController.addListener(_onChanged);
      row.percentController.addListener(_onChanged);
      _fundRows.add(row);
    }
  }

  String _defaultPercentText(double value, double total) {
    if (total == 0) return '';
    return AppFormatters.decimalValue((value / total) * 100);
  }

  void _onChanged() {
    if (!_ready || !mounted) return;
    setState(() {});
    _savePrefs();
  }

  Future<void> _savePrefs() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setString(_generalBudgetKey, _generalBudgetController.text);
    await prefs.setString(_generalFundKey, _generalFundController.text);
    await prefs.setString(_generalStockKey, _generalStockController.text);
    await prefs.setString(_generalFxKey, _generalFxController.text);
    await prefs.setString(_fundBudgetKey, _fundBudgetController.text);
    await prefs.setString(
      _fundRowsKey,
      jsonEncode(
        _fundRows
            .map(
              (row) => {
                'code': row.codeController.text,
                'percent': row.percentController.text,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Portföy Dengeleyici'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Genel Portföy'),
              Tab(text: 'Fon Dağılımı'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTab(),
            _buildFundTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    final fundValue = _fundHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    final stockValue = _stockHoldings.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
    const fxValue = 0.0;
    final currentTotal = fundValue + stockValue + fxValue;
    final currentFundPercent = _percent(fundValue, currentTotal);
    final currentStockPercent = _percent(stockValue, currentTotal);
    final currentFxPercent = _percent(fxValue, currentTotal);

    final budget = _parse(_generalBudgetController.text);
    final targetFundPercent = _parse(_generalFundController.text);
    final targetStockPercent = _parse(_generalStockController.text);
    final targetFxPercent = _parse(_generalFxController.text);
    final totalPercent =
        targetFundPercent + targetStockPercent + targetFxPercent;
    final isValid = (totalPercent - 100).abs() < 0.01;
    final generalAllocations = _allocateBudgetByDeficit(
      budget: budget,
      currentValues: {
        'Fon': fundValue,
        'Hisse': stockValue,
        'FX': fxValue,
      },
      targetPercents: {
        'Fon': targetFundPercent,
        'Hisse': targetStockPercent,
        'FX': targetFxPercent,
      },
      currentTotal: currentTotal,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(
          title: 'Mevcut Dağılım',
          rows: [
            _summaryRow('Fon', currentFundPercent),
            _summaryRow('Hisse', currentStockPercent),
            _summaryRow('FX', currentFxPercent),
          ],
        ),
        const SizedBox(height: 12),
        _buildTargetCard(
          children: [
            _textField(
              controller: _generalBudgetController,
              label: 'Ek yatırım bütçesi',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _generalFundController,
                    label: 'Fon %',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _generalStockController,
                    label: 'Hisse %',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _generalFxController,
                    label: 'FX %',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Toplam yüzde: ${AppFormatters.percentValue(totalPercent)}',
              style: TextStyle(
                color: isValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isValid) ...[
              const SizedBox(height: 8),
              const Text(
                'Yüzdeler toplamı 100 olmalı.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          title: 'Hedef dağılıma yaklaşmak için',
          rows: [
            _allocationRow(
              'Fonlara',
              generalAllocations['Fon'] ?? 0.0,
            ),
            _allocationRow(
              'Hisselere',
              generalAllocations['Hisse'] ?? 0.0,
            ),
            _allocationRow(
              'FX\'e',
              generalAllocations['FX'] ?? 0.0,
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _errorCard(),
        ],
      ],
    );
  }

  Widget _buildFundTab() {
    final fundTotal = _fundHoldings.fold<double>(
     0.0,
     (sum, item) => sum + item.currentValue,
    );
    final activeRows = _fundRows
       .where((row) => row.codeController.text.trim().isNotEmpty)
       .toList();
    final combinedPercent = activeRows.fold<double>(
     0.0,
     (sum, row) => sum + _parse(row.percentController.text),
    );
    final availableBudget = _parse(_fundBudgetController.text);
    final isCombinedValid = (combinedPercent - 100).abs() < 0.01;
    final currentValues = <String, double>{
     for (final holding in _fundHoldings) holding.fundCode: holding.currentValue,
    };
    for (final row in activeRows) {
     final code = row.codeController.text.trim().toUpperCase();
     currentValues.putIfAbsent(code, () => 0.0);
    }
    final fundAllocations = _allocateBudgetByDeficit(
     budget: availableBudget,
     currentValues: currentValues,
     targetPercents: {
       for (final row in activeRows)
         row.codeController.text.trim().toUpperCase():
             _parse(row.percentController.text),
     },
     currentTotal: fundTotal,
    );
    final resultRows = <Widget>[
     ...activeRows.map((row) {
       final code = row.codeController.text.trim().toUpperCase();
       return _allocationRow(
         code,
         fundAllocations[code] ?? 0.0,
       );
     }),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(
          title: 'Mevcut Fon Portföyü',
          rows: _fundHoldings.map((holding) {
            final currentPercent = _percent(holding.currentValue, fundTotal);
            return _summaryRow(
              holding.fundCode,
              currentPercent,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildTargetCard(
          children: [
            _textField(
              controller: _fundBudgetController,
              label: 'Ek yatırım bütçesi',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      final row = _FundSimulationRow();
                      row.codeController.addListener(_onChanged);
                      row.percentController.addListener(_onChanged);
                      _fundRows.add(row);
                    });
                    _savePrefs();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Fon Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._fundRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: row.codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Fon Adı / Fon Kodu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: _textField(
                        controller: row.percentController,
                        label: 'Hedef %',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _fundRows[index].dispose();
                          _fundRows.removeAt(index);
                        });
                        _savePrefs();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
            Text(
              'Toplam yüzde: ${AppFormatters.percentValue(combinedPercent)}',
              style: TextStyle(
                color: isCombinedValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isCombinedValid) ...[
              const SizedBox(height: 8),
              const Text(
                'Yüzdeler toplamı 100 olmalı.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          title: 'Hedef dağılıma yaklaşmak için',
          rows: resultRows,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _errorCard(),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required List<Widget> rows,
  }) {
    return Card(
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard({
    required List<Widget> children,
  }) {
    return Card(
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required List<Widget> rows,
  }) {
    return Card(
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sonuç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            AppFormatters.percentValue(percent),
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _allocationRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            AppFormatters.currencyValue(amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Card(
      color: Colors.red.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  double _percent(double value, double total) {
    if (total == 0) return 0.0;
    return value / total * 100;
  }

  Map<String, double> _allocateBudgetByDeficit({
    required double budget,
    required Map<String, double> currentValues,
    required Map<String, double> targetPercents,
    required double currentTotal,
  }) {
    if (budget <= 0 || targetPercents.isEmpty) {
      return {
        for (final key in targetPercents.keys) key: 0.0,
      };
    }

    final targetTotal = currentTotal + budget;
    final deficits = <String, double>{};
    var positiveTotal = 0.0;

    for (final entry in targetPercents.entries) {
      final currentValue = currentValues[entry.key] ?? 0.0;
      final desiredValue = targetTotal * entry.value / 100;
      final deficit = desiredValue - currentValue;
      final positiveDeficit = deficit > 0 ? deficit : 0.0;
      deficits[entry.key] = positiveDeficit;
      positiveTotal += positiveDeficit;
    }

    if (positiveTotal <= 0) {
      return {
        for (final entry in targetPercents.entries)
          entry.key: budget * entry.value / 100,
      };
    }

    return {
      for (final entry in deficits.entries)
        entry.key: budget * entry.value / positiveTotal,
    };
  }

}

class _FundSimulationRow {
  final TextEditingController codeController;
  final TextEditingController percentController;

  _FundSimulationRow({
    String code = '',
    String percent = '',
  })  : codeController = TextEditingController(text: code),
        percentController = TextEditingController(text: percent);

  void dispose() {
    codeController.dispose();
    percentController.dispose();
  }
}
