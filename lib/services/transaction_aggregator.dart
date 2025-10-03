import 'dart:math';

import 'package:intl/intl.dart';

import '../types/account_config.dart';
import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';
import '../types/transaction.dart';

class TransactionAggregator {
  List<MonthlySummary> buildMonthlySummaries(
    List<Transaction> transactions, {
    List<AccountConfig> accountConfigs = const [],
  }) {
    final senderLookup = _buildSenderLookup(accountConfigs);
    final Map<String, Map<String, _AccountGrouping>> grouped = {};
    for (final transaction in transactions) {
      final monthKey = transaction.monthKey();
      final meta = _metaFor(transaction, senderLookup);
      grouped.putIfAbsent(monthKey, () => {});
      grouped[monthKey]!.putIfAbsent(meta.key, () => _AccountGrouping(meta));
      grouped[monthKey]![meta.key]!.transactions.add(transaction);
    }

    final List<MonthlySummary> summaries = [];
    final sortedMonths = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final month in sortedMonths) {
      final accounts = grouped[month]!.values.map((group) {
        final transactions = group.transactions
          ..sort((a, b) => b.date.compareTo(a.date));
        return AccountMonthlySummary(
          monthKey: month,
          transactions: List.unmodifiable(transactions),
          accountSuffix: group.meta.accountSuffix,
          institution: group.meta.institution,
        );
      }).toList()
        ..sort(
          (a, b) => (b.creditTotal + b.debitTotal)
              .compareTo(a.creditTotal + a.debitTotal),
        );
      summaries.add(MonthlySummary(monthKey: month, accounts: accounts));
    }

    return summaries;
  }

  List<AccountSummary> buildAccountSummaries(
    List<Transaction> transactions, {
    List<AccountConfig> accountConfigs = const [],
  }) {
    final senderLookup = _buildSenderLookup(accountConfigs);
    final Map<String, _AccountGrouping> grouped = {};
    for (final transaction in transactions) {
      final meta = _metaFor(transaction, senderLookup);
      grouped.putIfAbsent(meta.key, () => _AccountGrouping(meta));
      grouped[meta.key]!.transactions.add(transaction);
    }

    final List<AccountSummary> summaries = [];
    for (final group in grouped.values) {
      final transactions = group.transactions
        ..sort((a, b) => b.date.compareTo(a.date));
      final monthlyGroups = <String, List<Transaction>>{};
      for (final t in transactions) {
        monthlyGroups.putIfAbsent(t.monthKey(), () => []);
        monthlyGroups[t.monthKey()]!.add(t);
      }
      final monthlySummaries = monthlyGroups.entries.map((monthly) {
        final items = monthly.value..sort((a, b) => b.date.compareTo(a.date));
        return AccountMonthlySummary(
          monthKey: monthly.key,
          transactions: List.unmodifiable(items),
          accountSuffix: group.meta.accountSuffix,
          institution: group.meta.institution,
        );
      }).toList()
        ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

      summaries.add(
        AccountSummary(
          accountKey: group.meta.key,
          institution: group.meta.institution,
          accountSuffix: group.meta.accountSuffix,
          monthlyBreakdowns: monthlySummaries,
        ),
      );
    }

    summaries.sort(
      (a, b) => (b.totalDebit + b.totalCredit)
          .compareTo(a.totalDebit + a.totalCredit),
    );

    return summaries;
  }

  DashboardOverview buildDashboardOverview(
    List<Transaction> transactions,
    List<AccountSummary> accounts,
  ) {
    final totalDebit = transactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalCredit = transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    final topAccounts = List<AccountSummary>.unmodifiable(
      accounts.take(min(3, accounts.length)).toList(),
    );
    final lastUpdated = transactions.isEmpty
        ? null
        : transactions.reduce(
            (a, b) => a.date.isAfter(b.date) ? a : b,
          ).date;

    return DashboardOverview(
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      transactionCount: transactions.length,
      topAccounts: topAccounts,
      lastUpdated: lastUpdated,
    );
  }

  String formatMonthLabel(String monthKey) {
    try {
      final date = DateFormat('yyyy-MM').parse(monthKey);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return monthKey;
    }
  }

  Map<String, AccountConfig> _buildSenderLookup(
    List<AccountConfig> accountConfigs,
  ) {
    final Map<String, AccountConfig> lookup = {};
    for (final config in accountConfigs) {
      for (final sender in config.senders) {
        if (sender.isEmpty) continue;
        lookup[sender] = config;
      }
    }
    return lookup;
  }

  _AccountMeta _metaFor(
    Transaction transaction,
    Map<String, AccountConfig> senderLookup,
  ) {
    final config = senderLookup[transaction.sender];
    if (config != null) {
      return _AccountMeta(
        key: config.id,
        institution: config.name,
        accountSuffix: config.accountSuffix,
      );
    }

    return _AccountMeta(
      key: transaction.accountKey,
      institution: transaction.institution,
      accountSuffix: transaction.accountSuffix,
    );
  }
}

class _AccountGrouping {
  _AccountGrouping(this.meta);

  final _AccountMeta meta;
  final List<Transaction> transactions = [];
}

class _AccountMeta {
  const _AccountMeta({
    required this.key,
    required this.institution,
    required this.accountSuffix,
  });

  final String key;
  final String institution;
  final String? accountSuffix;
}
