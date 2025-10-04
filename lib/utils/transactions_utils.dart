import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';

/// Groups a flat list of transactions into month buckets.
/// Assumes Transaction has a `monthKey()` like `yyyy-MM` (e.g., "2025-10").
Map<String, MonthlySummary> groupTransactionsByMonth(
    List<Transaction> transactions, {
      bool sortDescending = true,
    }) {
  final Map<String, MonthlySummary> summaries = {};

  for (final t in transactions) {
    final monthKey = t.monthKey();
    summaries.putIfAbsent(
      monthKey,
          () => MonthlySummary(month: monthKey, transactions: []),
    );
    summaries[monthKey]!.transactions.add(t);
  }

  // Sort each month’s transactions by date (latest first)
  for (final summary in summaries.values) {
    summary.transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // Sort months
  final sortedKeys = summaries.keys.toList()
    ..sort((a, b) => sortDescending ? b.compareTo(a) : a.compareTo(b));

  return {for (final key in sortedKeys) key: summaries[key]!};
}
