
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:trackify/components/monthly_expense_view.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsQuery _query = SmsQuery();
  List<Transaction> _transactions = [];
  Map<String, MonthlySummary> _monthlySummaries = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      await _querySmsMessages();
    } else if (status.isPermanentlyDenied) {
      // Optionally guide user to app settings to enable permission
      // openAppSettings();
    }
  }

  Future<void> _querySmsMessages() async {
    setState(() => _loading = true);

    try {
      final messages = await _query.querySms(kinds: [SmsQueryKind.inbox]);
      final filtered = messages.where(_isRelevantSms).toList();
      final parsed = filtered.map(_parseTransaction).whereType<Transaction>().toList();

      // Sort transactions by date descending
      parsed.sort((a, b) => b.date.compareTo(a.date));

      final summaries = _groupTransactionsByMonth(parsed);

      setState(() {
        _transactions = parsed;
        _monthlySummaries = summaries;
      });
    } catch (e) {
      debugPrint('Error querying SMS: $e');
      setState(() {
        _transactions = [];
        _monthlySummaries = {};
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isRelevantSms(SmsMessage message) {
    final sender = message.sender?.toLowerCase() ?? '';
    final body = message.body?.toLowerCase() ?? '';
    final bankSenders = ['indusb-s', 'indusind', 'indusb'];
    final hasSender = bankSenders.any((s) => sender.contains(s));
    final keywords = ['debited', 'credited'];
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
    }

    if (type == null) return null;

    final amountRegex = RegExp(r'(?:(?:rs\.?|inr)\s*)?([0-9]{1,3}(?:[,][0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
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

    final accountRegex = RegExp(r'(?:a/c|ac|account)\s*(?:no[:\s]*)?([xX\*\d]{2,})', caseSensitive: false);
    String? account;
    final accMatch = accountRegex.firstMatch(body);
    if (accMatch != null) {
      account = accMatch.group(1);
    } else {
      final fallbackAcc = RegExp(r'([xX\*]{2,}\d{2,}|ending\s*\d{2,4})', caseSensitive: false).firstMatch(body);
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

  Map<String, MonthlySummary> _groupTransactionsByMonth(List<Transaction> transactions) {
    final Map<String, MonthlySummary> summaries = {};
    for (final t in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(t.date);
      if (!summaries.containsKey(monthKey)) {
        summaries[monthKey] = MonthlySummary(month: monthKey, transactions: []);
      }
      summaries[monthKey]!.transactions.add(t);
    }
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Tracker'),
        ),
        body: RefreshIndicator(
          onRefresh: _querySmsMessages,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _monthlySummaries.isNotEmpty
              ? MonthlyExpenseView(monthlySummaries: _monthlySummaries)
              : Center(
            child: Text(
              'No transactions to show.\nPull down to refresh.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _querySmsMessages,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}






