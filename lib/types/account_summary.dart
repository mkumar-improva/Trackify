import 'package:intl/intl.dart';

import 'transaction.dart';

class AccountMonthlySummary {
  AccountMonthlySummary({
    required this.monthKey,
    required this.transactions,
    required this.accountSuffix,
    required this.institution,
  });

  final String monthKey;
  final List<Transaction> transactions;
  final String? accountSuffix;
  final String institution;

  double get debitTotal => transactions
      .where((t) => t.isDebit)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get creditTotal => transactions
      .where((t) => t.isCredit)
      .fold(0.0, (sum, t) => sum + t.amount);
}

class AccountSummary {
  AccountSummary({
    required this.accountKey,
    required this.institution,
    required this.accountSuffix,
    required List<AccountMonthlySummary> monthlyBreakdowns,
  }) : monthlyBreakdowns = List.unmodifiable(monthlyBreakdowns);

  final String accountKey;
  final String institution;
  final String? accountSuffix;
  final List<AccountMonthlySummary> monthlyBreakdowns;

  double get totalDebit =>
      monthlyBreakdowns.fold(0.0, (sum, m) => sum + m.debitTotal);

  double get totalCredit =>
      monthlyBreakdowns.fold(0.0, (sum, m) => sum + m.creditTotal);

  double get net => totalCredit - totalDebit;

  String get displayLabel {
    final suffix = accountSuffix == null || accountSuffix!.isEmpty
        ? '••••'
        : accountSuffix!.padLeft(4, '•');
    return '$institution · $suffix';
  }

  List<AccountMonthlySummary> monthsSortedDescending() {
    final sorted = List<AccountMonthlySummary>.of(monthlyBreakdowns);
    sorted.sort((a, b) => b.monthKey.compareTo(a.monthKey));
    return sorted;
  }
}

class MonthlySummary {
  MonthlySummary({
    required this.monthKey,
    required List<AccountMonthlySummary> accounts,
  }) : accounts = List.unmodifiable(accounts);

  final String monthKey;
  final List<AccountMonthlySummary> accounts;

  double get totalDebit =>
      accounts.fold(0.0, (sum, account) => sum + account.debitTotal);

  double get totalCredit =>
      accounts.fold(0.0, (sum, account) => sum + account.creditTotal);

  DateTime get monthDate => DateFormat('yyyy-MM').parse(monthKey);
}
