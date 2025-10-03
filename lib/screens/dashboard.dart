import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.overview,
    required this.accounts,
    this.onViewTimeline,
    this.onManageAccounts,
    this.onRefresh,
  });

  final DashboardOverview overview;
  final List<AccountSummary> accounts;
  final VoidCallback? onViewTimeline;
  final VoidCallback? onManageAccounts;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _BalanceCard(overview: overview),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _QuickActionsRow(
              onViewTimeline: onViewTimeline,
              onManageAccounts: onManageAccounts,
              onRefresh: onRefresh,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 0, 8),
          sliver: SliverToBoxAdapter(
            child: _AccountsCarousel(accounts: accounts),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _InsightsCard(overview: overview),
              const SizedBox(height: 16),
              _TopAccountsList(accounts: accounts, overview: overview),
            ]),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF174EA6), Color(0xFF4285F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33174EA6),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total balance',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(overview.net),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _BalancePill(
                  label: 'Money in',
                  amount: overview.totalCredit,
                  color: const Color(0xFF9CE0B7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalancePill(
                  label: 'Money out',
                  amount: overview.totalDebit,
                  color: const Color(0xFFF8BBD0),
                ),
              ),
            ],
          ),
          if (overview.lastUpdated != null) ...[
            const SizedBox(height: 24),
            Text(
              'As of ${DateFormat('MMM d, h:mm a').format(overview.lastUpdated!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactSimpleCurrency(name: 'INR');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency.format(amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    this.onViewTimeline,
    this.onManageAccounts,
    this.onRefresh,
  });

  final VoidCallback? onViewTimeline;
  final VoidCallback? onManageAccounts;
  final VoidCallback? onRefresh;

  void _defaultSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.qr_code_scanner,
            label: 'Scan & pay',
            onTap: (context) => _defaultSnack(context, 'Scan & pay'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.timeline_outlined,
            label: 'Timeline',
            onTap: (context) {
              if (onViewTimeline != null) {
                onViewTimeline!();
              } else {
                _defaultSnack(context, 'Timeline');
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.manage_accounts_outlined,
            label: 'Accounts',
            onTap: (context) {
              if (onManageAccounts != null) {
                onManageAccounts!();
              } else {
                _defaultSnack(context, 'Accounts');
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.sync,
            label: 'Refresh',
            onTap: (context) {
              if (onRefresh != null) {
                onRefresh!();
              } else {
                _defaultSnack(context, 'Refresh');
              }
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(context),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsCarousel extends StatelessWidget {
  const _AccountsCarousel({required this.accounts});

  final List<AccountSummary> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (accounts.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.centerLeft,
        child: Text(
          'Your bank accounts will appear here once we detect SMS alerts.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final currency = NumberFormat.compactSimpleCurrency(name: 'INR');

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = accounts[index];
          final net = account.net;
          final netColor = net >= 0
              ? theme.colorScheme.primary
              : theme.colorScheme.error;
          return Container(
            width: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.institution,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '•••• ${account.accountSuffix ?? '0000'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Net',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(net.abs()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: netColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVolume = overview.totalCredit + overview.totalDebit;
    final inflowShare = totalVolume == 0 ? 0.5 : overview.totalCredit / totalVolume;
    final outflowShare = 1 - inflowShare;
    final currency = NumberFormat.simpleCurrency(name: 'INR');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cashflow insights',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inflow', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(overview.totalCredit),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outflow', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(overview.totalDebit),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: inflowShare,
                minHeight: 12,
                color: Colors.green.shade500,
                backgroundColor: Colors.red.shade300.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(inflowShare * 100).round()}% incoming'),
                Text('${(outflowShare * 100).round()}% outgoing'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 18),
                const SizedBox(width: 8),
                Text('${overview.transactionCount} transactions analysed'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAccountsList extends StatelessWidget {
  const _TopAccountsList({
    required this.accounts,
    required this.overview,
  });

  final List<AccountSummary> accounts;
  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');

    final visibleAccounts = overview.topAccounts.isNotEmpty
        ? overview.topAccounts
        : accounts.take(3).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top accounts',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (visibleAccounts.isEmpty)
              Text(
                'Make a few transactions to see which accounts are most active.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...visibleAccounts.map((account) {
                final net = account.net;
                final netColor = net >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700;
                final displayInitial = account.institution.trim().isEmpty
                    ? '?'
                    : account.institution.trim()[0].toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.12),
                        ),
                        child: Center(
                          child: Text(
                            displayInitial,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.displayLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'In ${currency.format(account.totalCredit)} · Out ${currency.format(account.totalDebit)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(net),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: netColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
