import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';
import 'package:trackify/dao/transaction_dao.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final TransactionDao _dao = TransactionDao();

  // ---------------- Merchant detection config ----------------
  static const List<String> _merchantKeywords = [
    'swiggy',
    'zomato',
    'amazon',
    'amazon pay',
    'amazonpay',
    'flipkart',
    'meesho',
    'zepto',
    'myntra',
    'ajio',
    'nykaa',
    'bigbasket',
    'blinkit',
    'ola',
    'uber',
    'rapido',
    'paytm mall',
    'paytmmall',
    'tata neu',
    'tataneu',
    'jiomart',
    'jio mart',
    'snapdeal',
    'bookmyshow',
    'book my show',
    'make my trip',
    'makemytrip',
    'cleartrip',
    'irctc',
  ];

  // Matches:
  //  • brand words (with spacing variants)
  //  • "to <merchant>"
  //  • UPI handles like merchant@bank (local part contains the brand)
  static final RegExp _merchantRegex = RegExp(
    r'(?<![a-z0-9])(?:'
    r'swiggy|zomato|amazon(?:\s*pay)?|flipkart|meesho|zepto|myntra|ajio|nykaa|bigbasket|blinkit|ola|uber|rapido|paytm(?:\s*mall)?|tata\s*neu|jiomart|jio\s*mart|snapdeal|book\s*my\s*show|bookmyshow|make\s*my\s*trip|makemytrip|cleartrip|irctc'
    r')(?!(?:[a-z0-9]))'
    r'|'
    r'(?:to\s+(?:swiggy|zomato|amazon(?:\s*pay)?|flipkart|meesho|zepto|myntra|ajio|nykaa|bigbasket|blinkit|ola|uber|rapido|paytm(?:\s*mall)?|tata\s*neu|jiomart|jio\s*mart|snapdeal|book\s*my\s*show|bookmyshow|makemytrip|cleartrip|irctc))'
    r'|'
    r'(?:\b([a-z0-9._-]*?(?:swiggy|zomato|amazonpay|amazon|flipkart|meesho|zepto|myntra|ajio|nykaa|bigbasket|blinkit|ola|uber|rapido|paytm|tataneu|jiomart|bookmyshow|makemytrip|cleartrip|irctc))@[a-z0-9._-]+\b)',
    caseSensitive: false,
  );

  // Normalize things like "book my show" -> "bookmyshow", "tata neu" -> "tataneu"
  static String _normalizeMerchantKey(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// Try to extract which merchant this SMS is about. Returns a normalized key or null.
  String? matchMerchant(String senderLower, String bodyLower) {
    // quick contains
    for (final kw in _merchantKeywords) {
      final kNorm = _normalizeMerchantKey(kw);
      if (senderLower.contains(kNorm) || bodyLower.contains(kNorm)) {
        return kNorm;
      }
    }

    // regex matches (brand words / "to <merchant>" / UPI handles)
    final m =
        _merchantRegex.firstMatch(bodyLower) ??
        _merchantRegex.firstMatch(senderLower);
    if (m != null) {
      final raw = (m.group(0) ?? m.group(1) ?? '').toLowerCase();
      if (raw.isNotEmpty) return _normalizeMerchantKey(raw);
    }

    // UPI handle heuristic: local-part contains brand
    final upiHandles = RegExp(
      r'\b([a-z0-9._-]+)@[a-z0-9._-]+\b',
      caseSensitive: false,
    );
    for (final h in upiHandles.allMatches(bodyLower)) {
      final local = (h.group(1) ?? '').toLowerCase();
      for (final kw in _merchantKeywords) {
        final kNorm = _normalizeMerchantKey(kw);
        if (local.contains(kNorm)) return kNorm;
      }
    }
    return null;
  }

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

  Future<List<SmsMessage>> fetchSmsByKeywords(List<String> keywords) async {
    final messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
    final lowerKeywords = keywords.map((k) => k.toLowerCase()).toList();

    return messages.where((message) {
      final body = message.body?.toLowerCase() ?? '';
      return lowerKeywords.any((k) => body.contains(k));
    }).toList();
  }

  Future<List<String>> listAllSendersWithRelevantSms(
    List<String> keywords,
  ) async {
    final transactionKeywords = [
      'debited',
      'credited',
      'sent via upi',
      'balance',
    ];

    final senders = <String>{};
    final messages = await fetchSmsByKeywords(keywords);

    for (var message in messages) {
      final sender = message.sender?.toLowerCase() ?? '';
      final body = message.body?.toLowerCase() ?? '';

      final hasKeyword = transactionKeywords.any(
        (k) => body.contains(k.toLowerCase()),
      );
      if (hasKeyword && sender.isNotEmpty) {
        senders.add(sender);
      }
    }

    return senders.toList()..sort();
  }

  Future<List<SmsMessage>> getAllSmsFromSender(String sender) async {
    final messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
    final List<String> lowerSender = sender.toLowerCase().split(",");

    return messages.where((message) {
      final msgSender = message.sender?.toLowerCase() ?? '';
      return lowerSender.contains(msgSender);
    }).toList();
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

  /// Scans inbox, parses as usual, and returns only transactions that match known merchants.
  /// Optionally pass a subset of merchant names (e.g., ['swiggy','amazon']) to filter.
  Future<List<Transaction>> listMerchantTransactionsFromInbox({
    List<String>? merchants,
  }) async {
    final msgs = await _query.querySms(kinds: [SmsQueryKind.inbox]);
    final Set<String>? allow = merchants == null
        ? null
        : merchants.map(_normalizeMerchantKey).toSet();

    final results = <Transaction>[];
    for (final msg in msgs) {
      final sender = (msg.sender ?? '').toLowerCase();
      final body = (msg.body ?? '').toLowerCase();
      final merchant = matchMerchant(sender, body);
      if (merchant == null) continue;
      if (allow != null && !allow.contains(merchant)) continue;

      final tx = _parseTransaction(msg);
      if (tx != null) results.add(tx);
    }
    return results;
  }

  /// Same as above but grouped: { 'swiggy': [tx1, tx2], 'amazon': [tx3, ...], ... }
  Future<Map<String, List<Transaction>>> listMerchantTransactionsGrouped({
    List<String>? merchants,
  }) async {
    final flat = await listMerchantTransactionsFromInbox(merchants: merchants);
    final map = <String, List<Transaction>>{};
    for (final tx in flat) {
      final senderLower = tx.sender.toLowerCase();
      final bodyLower = tx.body.toLowerCase();
      final merchant = matchMerchant(senderLower, bodyLower);
      if (merchant == null) continue;
      (map[merchant] ??= <Transaction>[]).add(tx);
    }
    return map;
  }

  /// Returns: { '2025-10': { 'swiggy': [..], 'amazon': [..] }, '2025-09': {...} }
  Future<Map<String, Map<String, List<Transaction>>>>
  listMerchantTransactionsByMonth({List<String>? merchants}) async {
    final flat = await listMerchantTransactionsFromInbox(merchants: merchants);
    final out = <String, Map<String, List<Transaction>>>{};
    for (final tx in flat) {
      // Build month key "YYYY-MM"
      final d = tx.date;
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
      final senderLower = tx.sender.toLowerCase();
      final bodyLower = tx.body.toLowerCase();
      final merchant = matchMerchant(senderLower, bodyLower);
      if (merchant == null) continue;

      final monthMap = out.putIfAbsent(
        key,
        () => <String, List<Transaction>>{},
      );
      (monthMap[merchant] ??= <Transaction>[]).add(tx);
    }
    return out;
  }
}
