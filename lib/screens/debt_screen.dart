import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';
import '../features/debts/data/debt_repository.dart';
import '../models/debt.dart';

class DebtScreen extends StatefulWidget {
  final DebtRepository? repository;

  const DebtScreen({
    super.key,
    this.repository,
  });

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  late final DebtRepository _repository;
  List<Debt> _debts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DebtRepository();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final debts = await _repository.getAll();
      if (!mounted) return;
      setState(() {
        _debts = debts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Borçlar yüklenemedi: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddDialog() async {
    final debt = await showDialog<Debt>(
      context: context,
      builder: (context) => const _DebtFormDialog(),
    );

    if (debt == null) {
      return;
    }

    try {
      await _repository.add(
        description: debt.description,
        amount: debt.amount,
      );
      await _loadDebts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borç eklendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Borç eklenemedi: $e')),
      );
    }
  }

  Future<void> _confirmDelete(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borcu Sil'),
        content: Text('${debt.description} kaydını silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.delete(debt.id);
      await _loadDebts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borç silindi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDebts,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final totalDebt = _debts.fold<double>(
      0.0,
      (sum, debt) => sum + debt.amount,
    );

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadDebts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              _DebtSummaryCard(totalDebt: totalDebt),
              const SizedBox(height: 12),
              if (_debts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz borç kaydı yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Açıklama ve tutar ekleyerek başlayın.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._debts.map(
                  (debt) => _DebtListTile(
                    debt: debt,
                    onDelete: () => _confirmDelete(debt),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _openAddDialog,
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('Borç Ekle'),
          ),
        ),
      ],
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final double totalDebt;

  const _DebtSummaryCard({
    required this.totalDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toplam Borç',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currencyValue(totalDebt),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtListTile extends StatelessWidget {
  final Debt debt;
  final VoidCallback onDelete;

  const _DebtListTile({
    required this.debt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1D24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currencyValue(debt.amount),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[300],
              onPressed: onDelete,
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtFormDialog extends StatefulWidget {
  const _DebtFormDialog();

  @override
  State<_DebtFormDialog> createState() => _DebtFormDialogState();
}

class _DebtFormDialogState extends State<_DebtFormDialog> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    if (description.isEmpty || amount == null || amount <= 0) {
      setState(() {
        _errorText = 'Lütfen açıklama ve geçerli bir tutar girin.';
      });
      return;
    }

    Navigator.pop(
      context,
      Debt(
        id: '',
        description: description,
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Borç Ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Açıklama'),
            textInputAction: TextInputAction.next,
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Tutar'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
