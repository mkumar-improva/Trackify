import 'package:flutter/material.dart';
import 'package:trackify/types/transaction.dart';

class SpendingOverviewScreen extends StatelessWidget {
  SpendingOverviewScreen({super.key, required this.transactions});

  final List<Transaction> transactions;

  final Map<String, List<String>> _merchantKeywords = const {
    'Swiggy': ['swiggy'],
    'Zomato': ['zomato'],
    'OpenAI': ['openai'],
    'Claude': ['claude', 'anthropic'],
    'Netflix': ['netflix'],
    'FanCode': ['fancode'],
    'Hotstar': ['hotstar', 'disney+ hotstar', 'disney hotstar'],
    'Other OTT': [
      'prime video',
      'sonyliv',
      'sony liv',
      'aha',
      'zee5',
      'voot',
      'mx player',
      'lionsgate',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final merchantTotals = _calculateTotals();
    final totalSpending = merchantTotals.values.fold<double>(0, (sum, value) => sum + value);
    final entries = merchantTotals.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Overview')),
      body: entries.isEmpty
          ? const Center(
              child: Text('No matching transactions found for the selected merchants.'),
            )
          : ListView.builder(
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeaderCard(totalSpending);
                }
                final entry = entries[index - 1];
                final percentage = totalSpending > 0 ? (entry.value / totalSpending) * 100 : 0;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        entry.key.isNotEmpty
                            ? entry.key.substring(0, 1).toUpperCase()
                            : '?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    title: Text(entry.key),
                    subtitle: LinearProgressIndicator(
                      value: totalSpending > 0 ? entry.value / totalSpending : 0,
                      minHeight: 6,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${entry.value.toStringAsFixed(2)}'),
                        Text('${percentage.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Map<String, double> _calculateTotals() {
    final Map<String, double> totals = {
      for (final merchant in _merchantKeywords.keys) merchant: 0,
    };

    for (final transaction in transactions) {
      final amount = transaction.amount;
      if (transaction.type != 'DEBIT' || amount == null || amount <= 0) continue;
      final normalized = '${transaction.sender} ${transaction.body}'.toLowerCase();

      for (final entry in _merchantKeywords.entries) {
        final hasMatch = entry.value.any((keyword) => normalized.contains(keyword));
        if (hasMatch) {
          totals.update(entry.key, (value) => value + amount);
        }
      }
    }

    return totals;
  }

  Widget _buildHeaderCard(double totalSpending) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Spending',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${totalSpending.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Breakdown of spending across food delivery and OTT platforms.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
