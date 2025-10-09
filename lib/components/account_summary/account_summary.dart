import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:trackify/components/card/card_preview.dart';
import 'package:trackify/components/card/payment_store.dart';
import 'package:trackify/components/empty_state.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/theme/app_theme.dart';
import 'package:trackify/components/account_summary/transactions_view.dart';
import 'package:trackify/components/account_summary/trends_view.dart';
import 'package:trackify/types/homeTabs.dart';

class AccountSummary extends StatefulWidget {
  const AccountSummary({super.key});

  @override
  State<AccountSummary> createState() => _AccountSummaryState();
}

class _AccountSummaryState extends State<AccountSummary> {
  final SmsService _smsService = SmsService();
  final PaymentStore store = PaymentStore();
  
  // Active tab
  String _activeTab = homeTabs.first.value; // default to first tab
 // default to transactions view

  // raw transactions for the selected card
  List<SmsMessage> transactions = [];

  // UI state
  int selectedCard = 0;
  bool _loading = false;

  // transactions fetch state
  bool _txLoading = false;
  String? _txError;

  // month filter + pagination
  static const int _pageSize = 100;
  int _currentPage = 0;
  String? _selectedMonthKey; // format: 'yyyy-MM' (e.g., '2025-09')
  List<String> _monthKeys = []; // available months from current transactions
  final DateFormat _monthLabelFmt = DateFormat('MMM yyyy');

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _init();
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() => setState(() {});

  Future<void> _init() async {
    setState(() => _loading = true);
    await store.load();
    if (!mounted) return;
    setState(() => _loading = false);

    // Load transactions for the initially selected card (if any)
    if (store.items.isNotEmpty) {
      await _loadTransactionsForSelected();
    }
  }

  Future<void> _loadTransactionsForSelected() async {
    if (store.items.isEmpty) return;
    setState(() {
      _txLoading = true;
      _txError = null;
      _currentPage = 0; // reset pagination on reload
      _selectedMonthKey = null; // reset filter when switching card
    });
    try {
      final senders = store.items[selectedCard].senders ?? "";
      final msgs = await _smsService.getAllSmsFromSender(senders);

      // Sort newest first (optional but useful)
      msgs.sort((a, b) {
        final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        transactions = msgs;
        _rebuildMonths();
        _txLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _txError = e.toString();
        _txLoading = false;
      });
    }
  }

  void onCardTapped(int index) async {
    setState(() {
      selectedCard = index;
    });
    await _loadTransactionsForSelected();
  }

  String _fmtDateTime(DateTime dt) => DateFormat('dd MMM, hh:mm a').format(dt);

  /// Build distinct month keys (yyyy-MM) from current `transactions`
  void _rebuildMonths() {
    final set = <String>{};
    for (final m in transactions) {
      final dt = m.date;
      if (dt != null) {
        final key = _yyyyMm(dt);
        set.add(key);
      }
    }
    final keys = set.toList()
      ..sort((a, b) => b.compareTo(a)); // newest month first
    _monthKeys = keys;
  }

  /// 'yyyy-MM'
  String _yyyyMm(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';

  /// Human label from a 'yyyy-MM' key
  String _labelFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]) ?? 1970;
    final month = int.tryParse(parts[1]) ?? 1;
    return _monthLabelFmt.format(DateTime(year, month));
  }

  /// Apply month filter
  List<SmsMessage> get _filteredByMonth {
    if (_selectedMonthKey == null) return transactions;
    return transactions.where((m) {
      final dt = m.date;
      if (dt == null) return false;
      return _yyyyMm(dt) == _selectedMonthKey;
    }).toList();
  }

  /// Paginated view on filtered data
  List<SmsMessage> get _paged {
    final list = _filteredByMonth;
    final start = _currentPage * _pageSize;
    if (start >= list.length) return const [];
    final end = (start + _pageSize) > list.length
        ? list.length
        : (start + _pageSize);
    return list.sublist(start, end);
  }

  int get _totalPages {
    final total = _filteredByMonth.length;
    if (total == 0) return 1;
    return ((total - 1) / _pageSize).floor() + 1;
  }

  void _goPrevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _goNextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  void _onMonthChanged(String? key) {
    setState(() {
      _selectedMonthKey = key;
      _currentPage = 0; // reset on filter change
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = store.items;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const EmptyState();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Accounts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Horizontal carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(items.length, (index) {
                final method = items[index];
                final isSelected = index == selectedCard;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => onCardTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.linkPurple,
                                  width: 2,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(18),
                                ),
                              )
                            : null,
                        child: CardPreview(
                          method: method,
                          bankNameVisibility: true,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),
          Row(children: homeTabs.map((tab) {
            final isActive = _activeTab == tab.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activeTab = tab.value;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppTheme.linkPurple : null,
                  foregroundColor: isActive ? Colors.white : null,
                ),
                child: Text(
                  tab.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList()),

          const SizedBox(height: 8),
          
          // Show appropriate view based on active tab
          Expanded(
            child: _activeTab == 'transactions'
                ? TransactionsView(
                    txLoading: _txLoading,
                    txError: _txError,
                    paged: _paged,
                    filteredByMonth: _filteredByMonth,
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    monthKeys: _monthKeys,
                    selectedMonthKey: _selectedMonthKey,
                    onMonthChanged: _onMonthChanged,
                    goNextPage: _goNextPage,
                    goPrevPage: _goPrevPage,
                    fmtDateTime: _fmtDateTime,
                  )
                : const TrendsView(),
          )
        ]
      )
    );
  }
}
