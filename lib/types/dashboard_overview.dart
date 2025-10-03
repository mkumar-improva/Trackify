import 'account_summary.dart';

class DashboardOverview {
  DashboardOverview({
    required this.totalDebit,
    required this.totalCredit,
    required this.transactionCount,
    required this.topAccounts,
    required this.lastUpdated,
  });

  final double totalDebit;
  final double totalCredit;
  final int transactionCount;
  final List<AccountSummary> topAccounts;
  final DateTime? lastUpdated;

  double get net => totalCredit - totalDebit;
}
