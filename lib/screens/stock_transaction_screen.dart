import 'package:flutter/material.dart';
import '../features/transactions/data/stock_transaction_repository.dart';
import '../features/transactions/models/transaction_type.dart';
class StockTransactionScreen extends StatefulWidget {
  final String symbol;

  const StockTransactionScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<StockTransactionScreen> createState() =>
      _StockTransactionScreenState();
}

class _StockTransactionScreenState
    extends State<StockTransactionScreen> {
  final _repository = StockTransactionRepository();

  bool isBuy = true;

  final quantityController =
  TextEditingController();

  final priceController =
  TextEditingController();

  DateTime selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.symbol} İşlemi',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Alış'),
                icon: Icon(Icons.add),
              ),
              ButtonSegment(
                value: false,
                label: Text('Satış'),
                icon: Icon(Icons.remove),
              ),
            ],
            selected: {isBuy},
            onSelectionChanged: (value) {
              setState(() {
                isBuy = value.first;
              });
            },
          ),

          const SizedBox(height: 20),

          TextField(
            controller: quantityController,
            keyboardType:
            TextInputType.number,
            decoration:
            const InputDecoration(
              labelText: 'Adet',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: priceController,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
            const InputDecoration(
              labelText: 'Birim Fiyat',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(8),
              side: const BorderSide(),
            ),
            onTap: _pickDate,
            title: const Text('Tarih'),
            subtitle: Text(
              '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
            ),
            trailing:
            const Icon(Icons.calendar_today),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              final quantity =
              double.tryParse(
                quantityController.text,
              );

              final unitPrice =
              double.tryParse(
                priceController.text,
              );

              if (quantity == null ||
                  unitPrice == null) {
                return;
              }

              await _repository.add(
                stockSymbol: widget.symbol,
                date: selectedDate,
                type: isBuy
                    ? TransactionType.buy
                    : TransactionType.sell,
                quantity: quantity,
                unitPrice: unitPrice,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'İşlem kaydedildi',
                  ),
                ),
              );

              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}