import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters/app_formatters.dart';

class InvestmentAllocationPlannerScreen extends StatefulWidget {
  const InvestmentAllocationPlannerScreen({super.key});

  @override
  State<InvestmentAllocationPlannerScreen> createState() =>
      _InvestmentAllocationPlannerScreenState();
}

class _InvestmentAllocationPlannerScreenState
    extends State<InvestmentAllocationPlannerScreen> {
  static const _generalBudgetKey = 'planner.general.budget';
  static const _generalFundKey = 'planner.general.fund';
  static const _generalStockKey = 'planner.general.stock';
  static const _generalFxKey = 'planner.general.fx';
  static const _fundBudgetKey = 'planner.fund.budget';
  static const _fundRowsKey = 'planner.fund.rows';

  final _generalBudgetController = TextEditingController();
  final _generalFundController = TextEditingController();
  final _generalStockController = TextEditingController();
  final _generalFxController = TextEditingController();
  final _fundBudgetController = TextEditingController();
  final List<_FundRow> _fundRows = [];

  SharedPreferences? _prefs;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _generalBudgetController.addListener(_onChanged);
    _generalFundController.addListener(_onChanged);
    _generalStockController.addListener(_onChanged);
    _generalFxController.addListener(_onChanged);
    _fundBudgetController.addListener(_onChanged);
    _loadPrefs();
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

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    _generalBudgetController.text = prefs.getString(_generalBudgetKey) ?? '';
    _generalFundController.text = prefs.getString(_generalFundKey) ?? '';
    _generalStockController.text = prefs.getString(_generalStockKey) ?? '';
    _generalFxController.text = prefs.getString(_generalFxKey) ?? '';
    _fundBudgetController.text = prefs.getString(_fundBudgetKey) ?? '';

    final savedRows = prefs.getString(_fundRowsKey);
    if (savedRows != null) {
      final decoded = jsonDecode(savedRows) as List<dynamic>;
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        _fundRows.add(
          _FundRow(
            code: map['code'] as String? ?? '',
            percent: map['percent'] as String? ?? '',
          ),
        );
      }
    }

    for (final row in _fundRows) {
      row.codeController.addListener(_onChanged);
      row.percentController.addListener(_onChanged);
    }

    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  void _onChanged() {
    if (!mounted || !_ready) {
      return;
    }
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
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yatırım Dağıtım Planlayıcı'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Genel'),
              Tab(text: 'Fon'),
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
    final budget = _parse(_generalBudgetController.text);
    final fundPercent = _parse(_generalFundController.text);
    final stockPercent = _parse(_generalStockController.text);
    final fxPercent = _parse(_generalFxController.text);
    final totalPercent = fundPercent + stockPercent + fxPercent;
    final isValid = (totalPercent - 100).abs() < 0.01;
    final fundAmount = budget * fundPercent / 100;
    final stockAmount = budget * stockPercent / 100;
    final fxAmount = budget * fxPercent / 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput(
            controller: _generalBudgetController,
            label: 'Aylık yatırım bütçesi',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _generalFundController,
                  label: 'Fon %',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  controller: _generalStockController,
                  label: 'Hisse %',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
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
          const SizedBox(height: 16),
          Card(
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
                  const SizedBox(height: 12),
                  Text('Fon: ${AppFormatters.currencyValue(fundAmount)}'),
                  const SizedBox(height: 8),
                  Text('Hisse: ${AppFormatters.currencyValue(stockAmount)}'),
                  const SizedBox(height: 8),
                  Text('FX: ${AppFormatters.currencyValue(fxAmount)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundTab() {
    final budget = _parse(_fundBudgetController.text);
    final totalPercent = _fundRows.fold<double>(
      0.0,
      (sum, row) => sum + _parse(row.percentController.text),
    );
    final isValid = (totalPercent - 100).abs() < 0.01;
    final hasRows = _fundRows.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput(
            controller: _fundBudgetController,
            label: 'Aylık yatırım bütçesi',
          ),
          const SizedBox(height: 12),
          if (!hasRows) ...[
            Text(
              'Henüz fon eklenmedi.',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
          ],
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
                      decoration: const InputDecoration(
                        labelText: 'Fon kodu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: row.percentController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fon %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        row.dispose();
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
          TextButton.icon(
            onPressed: () {
              setState(() {
                final row = _FundRow();
                row.codeController.addListener(_onChanged);
                row.percentController.addListener(_onChanged);
                _fundRows.add(row);
              });
              _savePrefs();
            },
            icon: const Icon(Icons.add),
            label: const Text('➕ Fon Satırı Ekle'),
          ),
          if (hasRows) ...[
            const SizedBox(height: 8),
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
          if (hasRows && isValid) ...[
            const SizedBox(height: 16),
            Card(
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
                    const SizedBox(height: 12),
                    ..._fundRows.map((row) {
                      final percent = _parse(row.percentController.text);
                      final amount = budget * percent / 100;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${row.codeController.text.trim().isEmpty ? '-' : row.codeController.text.trim()}: '
                          '${AppFormatters.currencyValue(amount)}',
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput({
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
}

class _FundRow {
  final TextEditingController codeController;
  final TextEditingController percentController;

  _FundRow({
    String code = '',
    String percent = '',
  })  : codeController = TextEditingController(text: code),
        percentController = TextEditingController(text: percent);

  void dispose() {
    codeController.dispose();
    percentController.dispose();
  }
}
