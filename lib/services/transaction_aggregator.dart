import 'dart:math';

import 'package:intl/intl.dart';

import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';
import '../types/transaction.dart';

class TransactionAggregator {
  List<MonthlySummary> buildMonthlySummaries(List<Transaction> transactions) {
    final Map<String, Map<String, List<Transaction>>> grouped = {};
    for (final transaction in transactions) {
      final monthKey = transaction.monthKey();
      final accountKey = transaction.accountKey;
      grouped.putIfAbsent(monthKey, () => {});
      grouped[monthKey]!.putIfAbsent(accountKey, () => []);
      grouped[monthKey]![accountKey]!.add(transaction);
    }

    final List<MonthlySummary> summaries = [];
    final sortedMonths = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final month in sortedMonths) {
      final accounts = grouped[month]!.entries.map((entry) {
        final transactions = entry.value..sort((a, b) => b.date.compareTo(a.date));
        final sample = transactions.first;
        return AccountMonthlySummary(
          monthKey: month,
          transactions: List.unmodifiable(transactions),
          accountSuffix: sample.accountSuffix,
          institution: sample.institution,
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

  List<AccountSummary> buildAccountSummaries(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.accountKey, () => []);
      grouped[transaction.accountKey]!.add(transaction);
    }

    final List<AccountSummary> summaries = [];
    for (final entry in grouped.entries) {
      final transactions = entry.value..sort((a, b) => b.date.compareTo(a.date));
      final sample = transactions.first;
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
          accountSuffix: sample.accountSuffix,
          institution: sample.institution,
        );
      }).toList()
        ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

      summaries.add(
        AccountSummary(
          accountKey: entry.key,
          institution: sample.institution,
          accountSuffix: sample.accountSuffix,
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
}
