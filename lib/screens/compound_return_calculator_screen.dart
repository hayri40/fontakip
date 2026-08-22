import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters/app_formatters.dart';

enum _ReturnType { monthly, yearly }

class CompoundReturnCalculatorScreen extends StatefulWidget {
  const CompoundReturnCalculatorScreen({super.key});

  @override
  State<CompoundReturnCalculatorScreen> createState() =>
      _CompoundReturnCalculatorScreenState();
}

class _CompoundReturnCalculatorScreenState
    extends State<CompoundReturnCalculatorScreen> {
  static const _initialCapitalKey = 'compound.initialCapital';
  static const _monthlyInvestmentKey = 'compound.monthlyInvestment';
  static const _expectedReturnKey = 'compound.expectedReturn';
  static const _returnTypeKey = 'compound.returnType';
  static const _yearsKey = 'compound.years';

  final _initialCapitalController = TextEditingController();
  final _monthlyInvestmentController = TextEditingController();
  final _expectedReturnController = TextEditingController();
  final _yearsController = TextEditingController();

  SharedPreferences? _prefs;
  _ReturnType _returnType = _ReturnType.monthly;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialCapitalController.addListener(_onChanged);
    _monthlyInvestmentController.addListener(_onChanged);
    _expectedReturnController.addListener(_onChanged);
    _yearsController.addListener(_onChanged);
    _loadPrefs();
  }

  @override
  void dispose() {
    _initialCapitalController.dispose();
    _monthlyInvestmentController.dispose();
    _expectedReturnController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    _initialCapitalController.text = prefs.getString(_initialCapitalKey) ?? '';
    _monthlyInvestmentController.text =
        prefs.getString(_monthlyInvestmentKey) ?? '';
    _expectedReturnController.text = prefs.getString(_expectedReturnKey) ?? '';
    _yearsController.text = prefs.getString(_yearsKey) ?? '';

    final savedType = prefs.getString(_returnTypeKey);
    _returnType = savedType == 'yearly' ? _ReturnType.yearly : _ReturnType.monthly;

    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  void _onChanged() {
    if (!mounted || !_ready) return;
    setState(() {});
    _savePrefs();
  }

  Future<void> _savePrefs() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setString(_initialCapitalKey, _initialCapitalController.text);
    await prefs.setString(_monthlyInvestmentKey, _monthlyInvestmentController.text);
    await prefs.setString(_expectedReturnKey, _expectedReturnController.text);
    await prefs.setString(_yearsKey, _yearsController.text);
    await prefs.setString(
      _returnTypeKey,
      _returnType == _ReturnType.yearly ? 'yearly' : 'monthly',
    );
  }

  double _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  int _parseYears(String value) {
    final intValue = int.tryParse(value.trim());
    if (intValue != null) {
      return intValue < 0 ? 0 : intValue;
    }
    final doubleValue = _parse(value);
    if (doubleValue <= 0) return 0;
    return doubleValue.floor();
  }

  double _monthlyRate() {
    final input = _parse(_expectedReturnController.text) / 100;
    if (_returnType == _ReturnType.monthly) {
      return input;
    }
    return pow(1 + input, 1 / 12).toDouble() - 1;
  }

  double _annualFromMonthly(double monthlyRate) {
    return pow(1 + monthlyRate, 12).toDouble() - 1;
  }

  String _conversionNote() {
    final input = _parse(_expectedReturnController.text) / 100;
    if (_returnType == _ReturnType.monthly) {
      final annual = _annualFromMonthly(input) * 100;
      return '≈ ${AppFormatters.percentValue(annual)} yıllık bileşik karşılığı';
    }
    final monthly = (pow(1 + input, 1 / 12).toDouble() - 1) * 100;
    return '≈ ${AppFormatters.percentValue(monthly)} aylık karşılığı';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initialCapital = _parse(_initialCapitalController.text);
    final monthlyInvestment = _parse(_monthlyInvestmentController.text);
    final years = _parseYears(_yearsController.text);
    final months = years * 12;
    final monthlyRate = _monthlyRate();

    var portfolioValue = initialCapital;
    final yearlyValues = <double>[];
    for (var month = 1; month <= months; month++) {
      portfolioValue = portfolioValue * (1 + monthlyRate) + monthlyInvestment;
      if (month % 12 == 0) {
        yearlyValues.add(portfolioValue);
      }
    }

    final totalInvested = initialCapital + (monthlyInvestment * months);
    final totalGain = portfolioValue - totalInvested;
    final totalReturnPercent =
        totalInvested > 0 ? (totalGain / totalInvested) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bileşik Getiri Hesaplayıcı'),
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
                  _numberField(
                    controller: _initialCapitalController,
                    label: 'Başlangıç Sermayesi',
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _monthlyInvestmentController,
                    label: 'Aylık Ek Yatırım',
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _expectedReturnController,
                    label: 'Beklenen Getiri',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<_ReturnType>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Aylık'),
                          value: _ReturnType.monthly,
                          groupValue: _returnType,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _returnType = value;
                            });
                            _savePrefs();
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<_ReturnType>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Yıllık'),
                          value: _ReturnType.yearly,
                          groupValue: _returnType,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _returnType = value;
                            });
                            _savePrefs();
                          },
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _conversionNote(),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _yearsController,
                    label: 'Süre (Yıl)',
                    decimal: false,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sonuç',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _resultRow('Toplam Yatırılan Para', totalInvested),
                  const SizedBox(height: 8),
                  _resultRow('Tahmini Portföy Değeri', portfolioValue),
                  const SizedBox(height: 8),
                  _resultRow('Toplam Kazanç', totalGain),
                  const SizedBox(height: 8),
                  Text('Toplam Getiri: ${AppFormatters.percentValue(totalReturnPercent)}'),
                ],
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
                    'Yıllık Büyüme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (yearlyValues.isEmpty)
                    Text(
                      'Yıl bilgisi girildiğinde yıllık büyüme burada gösterilir.',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ...yearlyValues.asMap().entries.map((entry) {
                    final year = entry.key + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text('Yıl $year')),
                          Text(AppFormatters.currencyValue(entry.value)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool decimal = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _resultRow(String label, double value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(AppFormatters.currencyValue(value)),
      ],
    );
  }
}
