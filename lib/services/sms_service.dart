import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';
import 'package:trackify/dao/transaction_dao.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final TransactionDao _dao = TransactionDao();

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return false;
  }

  /// 1) Read inbox, parse relevant messages, and persist into SQLite.
  /// Returns number of inserted (non-duplicate) rows.
  Future<int> syncFromInbox() async {
    final messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);

    final filtered = messages.where(_isRelevantSms).toList();
    final parsed = filtered
        .map(_parseTransaction)
        .whereType<Transaction>()
        .toList();

    // Bulk insert; UNIQUE(sender,body,date) prevents dupes.
    await _dao.insertMany(parsed);

    // We can't easily know how many were ignored due to conflict without
    // additional logic; return the attempted insert count for now.
    return parsed.length;
  }

  /// 2) Fetch month-wise summaries from the DB for UI.
  Future<Map<String, MonthlySummary>> loadMonthlySummaries() {
    return _dao.fetchMonthlySummaries();
  }

  /// 3) (Optional) Fetch one month on demand
  Future<MonthlySummary> loadOneMonth(String yyyyMm) async {
    final txs = await _dao.fetchByMonthKey(yyyyMm);
    return MonthlySummary(month: yyyyMm, transactions: txs);
  }

  // ---------- SMS parsing logic (unchanged) ----------

  bool _isRelevantSms(SmsMessage message) {
    final sender = message.sender?.toLowerCase() ?? '';
    final body = message.body?.toLowerCase() ?? '';
    final bankSenders = ['indusb-s', 'indusind', 'indusb', 'fedbnk-s'];
    final hasSender = bankSenders.any((s) => sender.contains(s));
    final keywords = ['debited', 'credited', 'sent via upi'];
    final hasKeyword = keywords.any((k) => body.contains(k));
    return hasSender && hasKeyword;
  }

  Transaction? _parseTransaction(SmsMessage message) {
    final body = message.body ?? '';
    final sender = message.sender ?? '';
    final date = message.date ?? DateTime.now();
    final lower = body.toLowerCase();

    String? type;
    if (lower.contains('debited')) {
      type = 'DEBIT';
    } else if (lower.contains('credited')) {
      type = 'CREDIT';
    } else if (lower.contains('sent via upi')) {
      type = 'DEBIT';
    }
    if (type == null) return null;

    final amountRegex = RegExp(
      r'(?:(?:rs\.?|inr)\s*)?([0-9]{1,3}(?:[,][0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    double? amount;
    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch != null) {
      final rawAmount = amountMatch.group(1) ?? '';
      final normalized = rawAmount.replaceAll(',', '');
      try {
        amount = double.parse(normalized);
      } catch (_) {
        amount = null;
      }
    }

    final accountRegex = RegExp(
      r'(?:a/c|ac|account)\s*(?:no[:\s]*)?([xX\*\d]{2,})',
      caseSensitive: false,
    );
    String? account;
    final accMatch = accountRegex.firstMatch(body);
    if (accMatch != null) {
      account = accMatch.group(1);
    } else {
      final fallbackAcc = RegExp(
        r'([xX\*]{2,}\d{2,}|ending\s*\d{2,4})',
        caseSensitive: false,
      ).firstMatch(body);
      account = fallbackAcc?.group(0);
    }

    return Transaction(
      sender: sender,
      body: body,
      type: type,
      amount: amount,
      account: account,
      date: date,
    );
  }
}
