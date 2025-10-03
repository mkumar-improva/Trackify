import 'package:intl/intl.dart';

enum TransactionDirection { debit, credit }

enum MessageBox { inbox, sent }

class Transaction {
  Transaction({
    required this.sender,
    required this.body,
    required this.direction,
    required this.amount,
    required this.accountSuffix,
    required this.institution,
    required this.date,
    this.counterparty,
    required this.messageBox,
  });

  final String sender;
  final String body;
  final TransactionDirection direction;
  final double amount;
  final String? accountSuffix;
  final String institution;
  final DateTime date;
  final String? counterparty;
  final MessageBox messageBox;

  bool get isCredit => direction == TransactionDirection.credit;

  bool get isDebit => direction == TransactionDirection.debit;

  String get accountKey =>
      '${institution.toLowerCase()}_${accountSuffix ?? 'unknown'}';

  String monthKey() => DateFormat('yyyy-MM').format(date);
}
