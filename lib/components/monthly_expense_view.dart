import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/transaction_aggregator.dart';
import '../types/account_summary.dart';
import '../types/transaction.dart';

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
    final theme = Theme.of(context);

    if (monthlySummaries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 120),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 72,
                color: const Color(0xFF1B4332),
              ),
              const SizedBox(height: 24),
              Text(
                'No activity yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We will craft your Trackify timeline once we detect transaction alerts from your SMS inbox.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 140),
      itemCount: monthlySummaries.length,
      itemBuilder: (context, index) {
        final summary = monthlySummaries[index];
        final monthLabel = aggregator.formatMonthLabel(summary.monthKey);
        return Padding(
          padding: EdgeInsets.only(bottom: index == monthlySummaries.length - 1 ? 0 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...summary.accounts.map(
                (account) => _AccountTimelineCard(account: account),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountTimelineCard extends StatelessWidget {
  const _AccountTimelineCard({required this.account});

  final AccountMonthlySummary account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    final net = account.creditTotal - account.debitTotal;
    final netColor = net >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE9F5F0),
                child: Icon(
                  Icons.account_balance,
                  color: const Color(0xFF1B4332),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.institution,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '•••• ${account.accountSuffix ?? '0000'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6C8374),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Net',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF6C8374),
                    ),
                  ),
                  Text(
                    currency.format(net),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: netColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFE9F5F0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _FlowBadge(
                  icon: Icons.arrow_downward_rounded,
                  label: currency.format(account.creditTotal),
                  color: const Color(0xFF2D6A4F),
                ),
                const SizedBox(width: 20),
                _FlowBadge(
                  icon: Icons.arrow_upward_rounded,
                  label: currency.format(account.debitTotal),
                  color: const Color(0xFFB04E4E),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...account.transactions.asMap().entries.map(
            (entry) => _TimelineTransactionTile(
              transaction: entry.value,
              isLast: entry.key == account.transactions.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTransactionTile extends StatelessWidget {
  const _TimelineTransactionTile({
    required this.transaction,
    required this.isLast,
  });

  final Transaction transaction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    final amountColor = transaction.isCredit
        ? const Color(0xFF2D6A4F)
        : const Color(0xFFB04E4E);
    final signedAmount = transaction.isCredit
        ? '+${currency.format(transaction.amount)}'
        : '-${currency.format(transaction.amount)}';
    final headline = transaction.counterparty ?? transaction.sender;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: amountColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          amountColor.withOpacity(0.4),
                          theme.colorScheme.outlineVariant,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        headline,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      signedAmount,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM · h:mm a').format(transaction.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (transaction.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowBadge extends StatelessWidget {
  const _FlowBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
