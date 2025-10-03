class Transaction {
  final String sender;
  final String body;
  final String type; // DEBIT / CREDIT
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
}