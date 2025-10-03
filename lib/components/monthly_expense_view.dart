import 'package:flutter/material.dart';

import '../services/transaction_aggregator.dart';
import '../types/account_summary.dart';

class MonthlyExpenseView extends StatelessWidget {
  const MonthlyExpenseView({
    super.key,
    required this.monthlySummaries,
    required this.aggregator,
  });

  final List<MonthlySummary> monthlySummaries;
  final TransactionAggregator aggregator;

  @override
  Widget build(BuildContext context) {
    if (monthlySummaries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Text(
              'No transactions to show yet. Pull down to refresh.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: monthlySummaries.length,
      itemBuilder: (context, index) {
        final summary = monthlySummaries[index];
        final monthLabel = aggregator.formatMonthLabel(summary.monthKey);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Card(
            elevation: 1,
            child: ExpansionTile(
              title: Text(
                monthLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Inflow: ${summary.totalCredit.toStringAsFixed(2)} · Outflow: ${summary.totalDebit.toStringAsFixed(2)}',
              ),
              children: summary.accounts
                  .map((account) => _AccountSection(account: account))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.account,
  });

  final AccountMonthlySummary account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        child: ExpansionTile(
          title: Text(
            '${account.institution} · ${account.accountSuffix ?? '••••'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            'Inflow: ${account.creditTotal.toStringAsFixed(2)} · Outflow: ${account.debitTotal.toStringAsFixed(2)}',
          ),
          children: account.transactions.map((t) {
            final amountStyle = TextStyle(
              color: t.isCredit
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              fontWeight: FontWeight.bold,
            );
            return ListTile(
              title: Text(t.counterparty ?? t.sender),
              subtitle: Text(
                t.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (t.isCredit ? '+' : '-') + t.amount.toStringAsFixed(2),
                    style: amountStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(t.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthLabel(date.month)} ${date.year}';
  }

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
