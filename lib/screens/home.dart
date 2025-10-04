import 'package:flutter/material.dart';
import 'package:trackify/components/empty_state.dart';
import 'package:trackify/components/refresh_fab.dart';
import 'package:trackify/components/talk_to_kubo.dart';
import 'package:trackify/components/trackify_app_bar.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';
import 'package:trackify/components/monthly_expense_view.dart';
import 'package:trackify/utils/back_exit_helper.dart';
import 'package:trackify/utils/snackbar_utils.dart';
import 'package:trackify/utils/transactions_utils.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with BackExitHelper {
  final SmsService _smsService = SmsService();
  List<Transaction> _transactions = [];
  Map<String, MonthlySummary> _monthlySummaries = {};
  bool _loading = false;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  Future<void> _requestSmsPermission() async {
    final granted = await _smsService.requestPermission();
    if (!mounted) return;
    if (granted) await _querySmsMessages();
  }

  Future<void> _querySmsMessages() async {
    setState(() => _loading = true);
    try {
      final summaries = await _smsService.loadMonthlySummaries();
      final allTransactions = summaries.values.expand((s) => s.transactions).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final allSummaries = groupTransactionsByMonth(allTransactions);

      if (!mounted) return;
      setState(() {
        _transactions = allTransactions;
        _monthlySummaries = allSummaries;
      });
    } catch (e) {
      debugPrint('Error querying SMS: $e');
      if (!mounted) return;
      setState(() {
        _transactions = [];
        _monthlySummaries = {};
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncAndRefresh() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Snackbars.showFloating(messenger, 'Syncing messages...');
    setState(() => _loading = true);
    try {
      await _smsService.syncFromInbox();
      await _querySmsMessages();
    } catch (e) {
      debugPrint('Error syncing SMS: $e');
      Snackbars.showFloating(messenger, 'Sync failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTransactionsView() {
    return RefreshIndicator(
      onRefresh: _querySmsMessages,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _monthlySummaries.isNotEmpty
            ? MonthlyExpenseView(monthlySummaries: _monthlySummaries)
            : const EmptyState(),
      ),
    );
  }

  Widget _getCurrentPage() {
    if (_selectedIndex == 0) {
      return _buildTransactionsView();
    } else {
      return const TalkToKuboPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => handleBackPress(context),
      child: Scaffold(
        appBar: TrackifyAppBar(
          titleText: _selectedIndex == 0 ? 'Trackify' : 'Talk to Kubo',
        ),
        body: _getCurrentPage(),
        floatingActionButton: _selectedIndex == 0
            ? RefreshFab(onPressed: _syncAndRefresh)
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy),
              label: 'Talk to Kubo',
            ),
          ],
        ),
      ),
    );
  }
}
