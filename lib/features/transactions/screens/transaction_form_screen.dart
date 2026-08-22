import 'package:flutter/material.dart';

import '../../../core/formatters/app_formatters.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../data/transaction_repository.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;
  final String fundCode;

  const TransactionFormScreen({
    super.key,
    required this.fundCode,
    this.transaction,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = TransactionRepository();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();

  late DateTime _selectedDate;
  late TransactionType _selectedType;
  bool _isSaving = false;
  bool get _isReadOnly => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _quantityController.text = AppFormatters.quantityValue(tx.quantity);
      _unitPriceController.text = AppFormatters.decimalValue(tx.unitPrice);
      _selectedDate = tx.date;
      _selectedType = tx.type;
    } else {
      _selectedDate = DateTime.now();
      _selectedType = TransactionType.buy;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  double? get _totalAmount {
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final unitPrice = double.tryParse(_unitPriceController.text.replaceAll(',', '.'));
    if (quantity == null || unitPrice == null) return null;
    return quantity * unitPrice;
  }

  Future<void> _pickDate() async {
    if (_isReadOnly) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _repository.add(
        fundCode: widget.transaction?.fundCode ?? widget.fundCode.trim(),
        date: _selectedDate,
        type: _selectedType,
        quantity: double.parse(_quantityController.text.replaceAll(',', '.')),
        unitPrice: double.parse(_unitPriceController.text.replaceAll(',', '.')),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReadOnly ? 'İşlem Detayı' : 'Yeni İşlem'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildQuantityField(),
            const SizedBox(height: 16),
            _buildUnitPriceField(),
            const SizedBox(height: 16),
            _buildTotalField(),
            if (!_isReadOnly) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'İşlemi Kaydet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tarih',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İşlem Türü',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: TransactionType.values.map((type) {
            final isSelected = _selectedType == type;
            final color = type == TransactionType.buy ? Colors.green : Colors.red;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == TransactionType.buy ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: _isReadOnly
                      ? null
                      : () => setState(() => _selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[700]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      type.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? color : Colors.grey[400],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      readOnly: _isReadOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Adet',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Adet gerekli';
        }
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) {
          return 'Adet sıfırdan büyük olmalı';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildUnitPriceField() {
    return TextFormField(
      controller: _unitPriceController,
      readOnly: _isReadOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Birim Fiyat',
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Birim fiyat gerekli';
        }
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) {
          return 'Fiyat sıfırdan büyük olmalı';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTotalField() {
    final total = _totalAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Toplam',
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            AppFormatters.currencyValue(total),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}
