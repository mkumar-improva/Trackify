import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import '../types/transaction.dart';
import '../utils/account_parser.dart';
import '../utils/amount_parser.dart';

enum SmsPermissionResult { granted, denied, permanentlyDenied }

class SmsService {
  SmsService({SmsQuery? query}) : _query = query ?? SmsQuery();

  final SmsQuery _query;

  Future<SmsPermissionResult> ensurePermission() async {
    final currentStatus = await Permission.sms.status;
    if (currentStatus.isGranted) {
      return SmsPermissionResult.granted;
    }

    if (currentStatus.isPermanentlyDenied) {
      return SmsPermissionResult.permanentlyDenied;
    }

    if (currentStatus.isDenied || currentStatus.isRestricted) {
      final requested = await Permission.sms.request();
      if (requested.isGranted) return SmsPermissionResult.granted;
      if (requested.isPermanentlyDenied) {
        return SmsPermissionResult.permanentlyDenied;
      }
      return SmsPermissionResult.denied;
    }

    return SmsPermissionResult.denied;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<List<Transaction>> queryAndParseSms() async {
    final inboxMessages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
    final sentMessages = await _query.querySms(kinds: [SmsQueryKind.sent]);

    final parsed = <Transaction>[];
    for (final message in inboxMessages) {
      final transaction = _parseTransaction(message, MessageBox.inbox);
      if (transaction != null) parsed.add(transaction);
    }
    for (final message in sentMessages) {
      final transaction = _parseTransaction(message, MessageBox.sent);
      if (transaction != null) parsed.add(transaction);
    }

    parsed.sort((a, b) => b.date.compareTo(a.date));
    return parsed;
  }

  Transaction? _parseTransaction(SmsMessage message, MessageBox messageBox) {
    final body = message.body ?? '';
    if (body.isEmpty) return null;

    final normalizedBody = body.toLowerCase();
    if (!_isRelevantSms(normalizedBody)) return null;

    final sender = message.sender ?? '';
    final institution = AccountParser.inferInstitution(sender, body);
    final accountSuffix = AccountParser.extractAccountSuffix(body);
    final counterparty = AccountParser.extractCounterparty(body);

    final keywordIndex = _keywordIndex(normalizedBody);
    final amount =
        AmountParser.extractAmountNearKeyword(body, keywordIndex ?? 0);
    if (amount == null || amount <= 0) return null;

    final direction = _directionForMessage(normalizedBody, messageBox);
    if (direction == null) return null;

    final date = message.date ?? DateTime.now();

    return Transaction(
      sender: sender,
      body: body,
      direction: direction,
      amount: amount,
      accountSuffix: accountSuffix,
      institution: institution,
      date: date,
      counterparty: counterparty,
      messageBox: messageBox,
    );
  }

  bool _isRelevantSms(String normalizedBody) {
    final keywords = [
      'debited',
      'credited',
      'withdrawn',
      'deposited',
      'sent via upi',
      'received via upi',
      'upi transaction',
      'imps',
      'neft',
      'rtgs',
      'transfer',
      'payment',
    ];
    final hasKeyword = keywords.any(normalizedBody.contains);
    final hasAmount = RegExp(r'(rs\.?|inr|₹)').hasMatch(normalizedBody) ||
        RegExp(r'\d+[,.]\d{2}').hasMatch(normalizedBody);
    return hasKeyword && hasAmount;
  }

  int? _keywordIndex(String normalizedBody) {
    final orderedKeywords = [
      'debited',
      'credited',
      'withdrawn',
      'sent via upi',
      'received via upi',
      'upi transaction',
      'payment',
      'transfer',
    ];
    for (final keyword in orderedKeywords) {
      final index = normalizedBody.indexOf(keyword);
      if (index != -1) return index;
    }
    return null;
  }

  TransactionDirection? _directionForMessage(
    String normalizedBody,
    MessageBox messageBox,
  ) {
    if (normalizedBody.contains('credited') || normalizedBody.contains('received')) {
      return TransactionDirection.credit;
    }

    if (normalizedBody.contains('debited') ||
        normalizedBody.contains('withdrawn') ||
        normalizedBody.contains('sent via upi') ||
        normalizedBody.contains('transfer') ||
        normalizedBody.contains('payment')) {
      return TransactionDirection.debit;
    }

    if (messageBox == MessageBox.sent) {
      return TransactionDirection.debit;
    }

    if (messageBox == MessageBox.inbox && normalizedBody.contains('deposited')) {
      return TransactionDirection.credit;
    }

    return null;
  }
}
