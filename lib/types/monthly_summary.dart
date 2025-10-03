import 'package:trackify/types/transaction.dart';

class MonthlySummary {
  final String month;
  final List<Transaction> transactions;
  double _totalDebit = 0;
  double _totalCredit = 0;

  MonthlySummary({required this.month, required this.transactions}) {
    for (final t in transactions) {
      if (t.type == 'DEBIT' && t.amount != null) {
        _totalDebit += t.amount!;
      } else if (t.type == 'CREDIT' && t.amount != null) {
        _totalCredit += t.amount!;
      }
    }
  }

  double get totalDebit => _totalDebit;
  double get totalCredit => _totalCredit;
}