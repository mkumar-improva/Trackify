import 'package:intl/intl.dart';

class Transaction {
  final String sender;
  final String body;
  final String type; // 'DEBIT' or 'CREDIT'
  final double? amount;
  final String? account;
  final DateTime date;

  Transaction({
    required this.sender,
    required this.body,
    required this.type,
    required this.amount,
    required this.account,
    required this.date,
  });

  String monthKey() => DateFormat('yyyy-MM').format(date);
}
