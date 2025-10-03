import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';
import '../types/transaction.dart';

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
    final allTransactions = _collectTransactions(accounts);
    final monthlyNet = _monthlyNetSeries(accounts);
    final topContacts = _topCounterparties(allTransactions).take(4).toList();
    final spendingCategories = _categoryTotals(
      allTransactions,
      TransactionDirection.debit,
    );
    final incomeCategories = _categoryTotals(
      allTransactions,
      TransactionDirection.credit,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _BalanceSummaryCard(
              overview: overview,
              onManageAccounts: onManageAccounts,
              onRefresh: onRefresh,
              onViewTimeline: onViewTimeline,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _OverviewStatsRow(overview: overview),
          ),
        ),
        if (topContacts.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            sliver: SliverToBoxAdapter(
              child: _ContactsCard(counterparties: topContacts),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _ProgressInsightCard(points: monthlyNet),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _SpendingBreakdownCard(spending: spendingCategories),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
          sliver: SliverToBoxAdapter(
            child: _IncomeListCard(categories: incomeCategories),
          ),
        ),
      ],
    );
  }

  List<Transaction> _collectTransactions(List<AccountSummary> accounts) {
    return accounts
        .expand(
          (account) => account.monthlyBreakdowns
              .expand((monthly) => monthly.transactions),
        )
        .toList();
  }

  List<_MonthlyPoint> _monthlyNetSeries(List<AccountSummary> accounts) {
    final Map<String, double> totals = {};
    for (final account in accounts) {
      for (final monthly in account.monthlyBreakdowns) {
        totals.update(
          monthly.monthKey,
          (value) => value + (monthly.creditTotal - monthly.debitTotal),
          ifAbsent: () => monthly.creditTotal - monthly.debitTotal,
        );
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final DateFormat parser = DateFormat('yyyy-MM');
    return entries
        .map(
          (entry) => _MonthlyPoint(
            date: parser.parse(entry.key),
            net: entry.value,
          ),
        )
        .toList();
  }

  List<_CounterpartyTotal> _topCounterparties(List<Transaction> transactions) {
    final Map<String, double> totals = {};
    for (final transaction in transactions) {
      final label = transaction.counterparty?.trim();
      if (label == null || label.isEmpty) continue;
      totals.update(
        label,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final items = totals.entries
        .map((entry) => _CounterpartyTotal(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return items;
  }

  List<_CategoryTotal> _categoryTotals(
    List<Transaction> transactions,
    TransactionDirection direction,
  ) {
    final Map<String, double> totals = {};
    for (final transaction in transactions) {
      if (transaction.direction != direction) continue;
      final label = (transaction.counterparty ?? transaction.institution).trim();
      if (label.isEmpty) continue;
      totals.update(
        label,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final items = totals.entries
        .map((entry) => _CategoryTotal(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return items.take(6).toList();
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({
    required this.overview,
    this.onViewTimeline,
    this.onManageAccounts,
    this.onRefresh,
  });

  final DashboardOverview overview;
  final VoidCallback? onViewTimeline;
  final VoidCallback? onManageAccounts;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF12372A), Color(0xFF1F5C44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3312342B),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Balance',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
                  icon: Icons.arrow_downward_rounded,
                  label: 'Money in',
                  amount: overview.totalCredit,
                  color: const Color(0xFFB9FBC0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalancePill(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Money out',
                  amount: overview.totalDebit,
                  color: const Color(0xFFFFC8DD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (onViewTimeline != null)
                _HeroActionButton(
                  icon: Icons.show_chart_rounded,
                  label: 'Timeline',
                  onPressed: onViewTimeline!,
                ),
              if (onManageAccounts != null)
                _HeroActionButton(
                  icon: Icons.account_balance_outlined,
                  label: 'Accounts',
                  onPressed: onManageAccounts!,
                ),
              if (onRefresh != null)
                _HeroActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  onPressed: onRefresh!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.compactSimpleCurrency(name: 'INR');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF123029)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white.withOpacity(0.08),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _OverviewStatsRow extends StatelessWidget {
  const _OverviewStatsRow({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactSimpleCurrency(name: 'INR');
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            title: 'Transactions',
            value: overview.transactionCount.toString(),
            color: const Color(0xFF84A98C),
            icon: Icons.receipt_long_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatTile(
            title: 'Inflow',
            value: currency.format(overview.totalCredit),
            color: const Color(0xFFCAD2C5),
            icon: Icons.download_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatTile(
            title: 'Outflow',
            value: currency.format(overview.totalDebit),
            color: const Color(0xFF95D5B2),
            icon: Icons.upload_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF123029)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF4F6355),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.counterparties});

  final List<_CounterpartyTotal> counterparties;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contacts with high progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: counterparties
                  .map((item) => _ContactChip(total: item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.total});

  final _CounterpartyTotal total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.compactSimpleCurrency(name: 'INR');
    final initials = total.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF6F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1B4332),
            child: Text(
              initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            total.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(total.total),
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2F6F57),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressInsightCard extends StatelessWidget {
  const _ProgressInsightCard({required this.points});

  final List<_MonthlyPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 22,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress rate',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F5F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Monthly',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF2F6F57),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? const _EmptyChartPlaceholder()
                : _SparklineChart(points: points),
          ),
        ],
      ),
    );
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({required this.points});

  final List<_MonthlyPoint> points;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _SparklinePainter(points: points),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points});

  final List<_MonthlyPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final double minY = points.map((p) => p.net).reduce(math.min);
    final double maxY = points.map((p) => p.net).reduce(math.max);
    final double range = (maxY - minY).abs() < 0.001 ? 1 : maxY - minY;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE6ECE8)
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final Path linePath = Path();
    final Path fillPath = Path();
    final double divisor = points.length <= 1 ? 1 : (points.length - 1).toDouble();
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final double x = size.width * (i / divisor);
      final double normalizedY = (point.net - minY) / range;
      final double y = size.height - (normalizedY * size.height);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x332D6A4F), Color(0x552D6A4F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = const Color(0xFF2D6A4F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final Paint dotPaint = Paint()
      ..color = const Color(0xFF40916C)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final double x = size.width * (i / divisor);
      final double normalizedY = (point.net - minY) / range;
      final double y = size.height - (normalizedY * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'We will plot your growth once we detect activity.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6C8374),
            ),
      ),
    );
  }
}

class _SpendingBreakdownCard extends StatelessWidget {
  const _SpendingBreakdownCard({
    required this.spending,
  });

  final List<_CategoryTotal> spending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 24,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top spending categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Month',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF6C8374),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: spending.isEmpty
                    ? const _DonutPlaceholder()
                    : _DonutChart(values: spending.map((e) => e.amount).toList()),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: spending
                      .map((item) => _CategoryTile(item: item))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _DonutPainter(values: values),
          size: Size.square(constraints.biggest.shortestSide),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values});

  final List<double> values;
  final List<Color> palette = const [
    Color(0xFF2D6A4F),
    Color(0xFF95D5B2),
    Color(0xFF40916C),
    Color(0xFF74C69D),
    Color(0xFFA8E6CF),
    Color(0xFF52B788),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    final double total = values.fold(0, (sum, v) => sum + v);
    if (total <= 0) {
      paint.color = const Color(0xFFDAE7DE);
      canvas.drawCircle(size.center(Offset.zero), size.width / 2.8, paint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      paint.color = palette[i % palette.length];
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2.8),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutPlaceholder extends StatelessWidget {
  const _DonutPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No spendings yet',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF9BAEA4)),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item});

  final _CategoryTotal item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            currency.format(item.amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2F6F57),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeListCard extends StatelessWidget {
  const _IncomeListCard({required this.categories});

  final List<_CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 24,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top income channels',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'We will surface your income sources once we detect credits.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6C8374),
                ),
              ),
            )
          else
            ...categories.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _progressFor(item, categories),
                            backgroundColor: const Color(0xFFE2EEE8),
                            color: const Color(0xFF2D6A4F),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      currency.format(item.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2F6F57),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _progressFor(_CategoryTotal item, List<_CategoryTotal> categories) {
    final double total = categories.fold(0, (sum, e) => sum + e.amount);
    if (total <= 0) return 0;
    return (item.amount / total).clamp(0.0, 1.0);
  }
}

class _MonthlyPoint {
  const _MonthlyPoint({required this.date, required this.net});

  final DateTime date;
  final double net;
}

class _CounterpartyTotal {
  const _CounterpartyTotal(this.name, this.total);

  final String name;
  final double total;
}

class _CategoryTotal {
  const _CategoryTotal(this.label, this.amount);

  final String label;
  final double amount;
}
