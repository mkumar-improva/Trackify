import 'package:flutter/material.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';
import 'package:trackify/components/monthly_expense_view.dart';


class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsService _smsService = SmsService();
  List<Transaction> _transactions = [];
  Map<String, MonthlySummary> _monthlySummaries = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  Future<void> _requestSmsPermission() async {
    final granted = await _smsService.requestPermission();
    if (granted) await _querySmsMessages();
  }

  Future<void> _querySmsMessages() async {
    setState(() => _loading = true);
    try {
      final parsed = await _smsService.queryAndParseSms();
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

  Map<String, MonthlySummary> _groupTransactionsByMonth(
    List<Transaction> transactions,
  ) {
    final Map<String, MonthlySummary> summaries = {};
    for (final t in transactions) {
      final monthKey = t.monthKey();
      summaries.putIfAbsent(
        monthKey,
        () => MonthlySummary(month: monthKey, transactions: []),
      );
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
        appBar: AppBar(title: const Text('Expense Tracker')),
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
