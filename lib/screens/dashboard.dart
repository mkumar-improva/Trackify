import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.overview,
    required this.accounts,
  });

  final DashboardOverview overview;
  final List<AccountSummary> accounts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCard(overview: overview),
        const SizedBox(height: 16),
        _AccountsActivityCard(accounts: accounts),
        const SizedBox(height: 16),
        _NetBalanceTrend(overview: overview),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _MetricTile(
                  label: 'Total Inflow',
                  value: currency.format(overview.totalCredit),
                  valueColor: Colors.green.shade600,
                  icon: Icons.arrow_downward,
                ),
                _MetricTile(
                  label: 'Total Outflow',
                  value: currency.format(overview.totalDebit),
                  valueColor: Colors.red.shade600,
                  icon: Icons.arrow_upward,
                ),
                _MetricTile(
                  label: 'Net Balance',
                  value: currency.format(overview.net),
                  valueColor:
                      overview.net >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                  icon: Icons.account_balance_wallet,
                ),
                _MetricTile(
                  label: 'Transactions',
                  value: overview.transactionCount.toString(),
                  icon: Icons.list_alt,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (overview.lastUpdated != null)
              Text(
                'Last updated: ${DateFormat('d MMM y, hh:mm a').format(overview.lastUpdated!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(icon, size: 18),
                ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _AccountsActivityCard extends StatelessWidget {
  const _AccountsActivityCard({required this.accounts});

  final List<AccountSummary> accounts;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No bank accounts detected yet. Keep transacting to see insights here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final currency = NumberFormat.simpleCurrency(name: 'INR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final net = account.net;
                final netColor = net >= 0 ? Colors.green.shade600 : Colors.red.shade600;
                final debit = currency.format(account.totalDebit);
                final credit = currency.format(account.totalCredit);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(account.displayLabel),
                  subtitle: Text('Inflow $credit · Outflow $debit'),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currency.format(net),
                        style: TextStyle(
                          color: netColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${account.monthlyBreakdowns.length} months'),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(),
              itemCount: accounts.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetBalanceTrend extends StatelessWidget {
  const _NetBalanceTrend({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final total = overview.totalDebit + overview.totalCredit;
    final creditFraction = total == 0 ? 0.5 : overview.totalCredit / total;
    final debitFraction = total == 0 ? 0.5 : overview.totalDebit / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cashflow Balance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: (creditFraction * 1000).round(),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                    ),
                  ),
                ),
                Expanded(
                  flex: (debitFraction * 1000).round(),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LegendEntry(label: 'Inflow', color: Colors.green.shade500),
                _LegendEntry(label: 'Outflow', color: Colors.red.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

