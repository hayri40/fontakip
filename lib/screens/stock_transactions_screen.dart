import 'package:flutter/material.dart';

import '../core/formatters/app_formatters.dart';
import '../features/transactions/data/stock_transaction_repository.dart';
import '../features/transactions/models/stock_transaction.dart';
import '../features/transactions/models/transaction_type.dart';

class StockTransactionsScreen extends StatefulWidget {
  const StockTransactionsScreen({super.key});

  @override
  State<StockTransactionsScreen> createState() => _StockTransactionsScreenState();
}

class _StockTransactionsScreenState extends State<StockTransactionsScreen> {
  final _repository = StockTransactionRepository();

  List<StockTransaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _repository.getAll();
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hisse işlemleri yüklenemedi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(StockTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: Text(
          '${transaction.stockSymbol} hissesine ait ${transaction.type.label.toLowerCase()} işlemini silmek istiyor musunuz?',
        ),
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

    if (confirmed != true) return;

    try {
      await _repository.delete(transaction.id);
      await _loadTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem silindi')),
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
                onPressed: _loadTransactions,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Henüz hisse işlemi yok',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _StockTransactionListTile(
            transaction: transaction,
            onDelete: () => _confirmDelete(transaction),
          );
        },
      ),
    );
  }
}

class _StockTransactionListTile extends StatelessWidget {
  final StockTransaction transaction;
  final VoidCallback onDelete;

  const _StockTransactionListTile({
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction.type == TransactionType.buy;
    final typeColor = isBuy ? Colors.green : Colors.red;

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
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        transaction.type.label,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        transaction.stockSymbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.date.day.toString().padLeft(2, '0')}.${transaction.date.month.toString().padLeft(2, '0')}.${transaction.date.year}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.quantityValue(transaction.quantity)} adet × ${AppFormatters.currencyValue(transaction.unitPrice)}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currencyValue(transaction.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}
