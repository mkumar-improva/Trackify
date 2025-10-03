import 'transaction.dart';

class MonthlySummary {
  final String month; // yyyy-MM
  final List<Transaction> transactions;

  MonthlySummary({required this.month, required this.transactions});

  double totalDebit() => transactions
      .where((t) => t.type == 'DEBIT' && (t.amount ?? 0) > 0)
      .fold(0.0, (s, t) => s + (t.amount ?? 0));

  double totalCredit() => transactions
      .where((t) => t.type == 'CREDIT' && (t.amount ?? 0) > 0)
      .fold(0.0, (s, t) => s + (t.amount ?? 0));
}
