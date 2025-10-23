import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:trackify/components/card/payment_store.dart';
import 'package:trackify/components/empty_state.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/theme/app_theme.dart';
import 'package:trackify/components/account_summary/transactions_view.dart';
import 'package:trackify/components/account_summary/trends_view.dart';
import 'package:trackify/types/homeTabs.dart';


class AccountSummary extends StatefulWidget {
  final int selectedCardIndex;
  final Function(int) onCardChanged;

  const AccountSummary({
    super.key,
    required this.selectedCardIndex,
    required this.onCardChanged,
  });

  @override
  State<AccountSummary> createState() => _AccountSummaryState();
}


class _AccountSummaryState extends State<AccountSummary> {
  final SmsService _smsService = SmsService();
  final PaymentStore store = PaymentStore();

  // Active tab
  String _activeTab = homeTabs.first.value;

  // Raw transactions for the selected card
  List<SmsMessage> allTransactions = [];

  // UI state
  bool _loading = false;

  // Transactions fetch state
  bool _txLoading = false;
  String? _txError;

  // Month filter + pagination
  static const int _pageSize = 50; // Number of transactions per page
  int _currentPage = 0;
  String? _selectedMonthKey;
  List<String> _monthKeys = [];

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

  @override
  void didUpdateWidget(AccountSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload transactions when card changes
    if (oldWidget.selectedCardIndex != widget.selectedCardIndex) {
      _loadTransactionsForSelected();
    }
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
    if (store.items.isEmpty || widget.selectedCardIndex >= store.items.length) {
      return;
    }
    
    setState(() {
      _txLoading = true;
      _txError = null;
      _currentPage = 0;
      _selectedMonthKey = null;
    });
    
    try {
      final senders = store.items[widget.selectedCardIndex].senders ?? "";
      final msgs = await _smsService.getAllSmsFromSender(senders);

      // Sort newest first
      msgs.sort((a, b) {
        final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        allTransactions = msgs;
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

  String _fmtDateTime(DateTime dt) => DateFormat('dd MMM, hh:mm a').format(dt);

  void _rebuildMonths() {
    final set = <String>{};
    for (final m in allTransactions) {
      final dt = m.date;
      if (dt != null) {
        final key = _yyyyMm(dt);
        set.add(key);
      }
    }
    final keys = set.toList()..sort((a, b) => b.compareTo(a));
    _monthKeys = keys;
  }

  String _yyyyMm(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';

  // STEP 1: Filter by month
  List<SmsMessage> get _filteredByMonth {
    if (_selectedMonthKey == null) return allTransactions;
    return allTransactions.where((m) {
      final dt = m.date;
      if (dt == null) return false;
      return _yyyyMm(dt) == _selectedMonthKey;
    }).toList();
  }

  // STEP 2: Group filtered transactions by merchant
  Map<String, List<SmsMessage>> get _groupedByMerchant {
    final grouped = <String, List<SmsMessage>>{};
    final unmatched = <SmsMessage>[];

    for (final msg in _filteredByMonth) {
      final sender = (msg.sender ?? '').toLowerCase();
      final body = (msg.body ?? '').toLowerCase();
      
      final merchant = _smsService.matchMerchant(sender, body);
      
      if (merchant != null) {
        (grouped[merchant] ??= <SmsMessage>[]).add(msg);
      } else {
        unmatched.add(msg);
      }
    }

    // Add unmatched to "others" category
    if (unmatched.isNotEmpty) {
      grouped['others'] = unmatched;
    }

    return grouped;
  }

  // Get sorted merchant names
  List<String> get _merchantNames {
    final names = _groupedByMerchant.keys.toList();
    // Sort alphabetically, but keep 'others' at the end
    names.sort((a, b) {
      if (a == 'others') return 1;
      if (b == 'others') return -1;
      return a.compareTo(b);
    });
    return names;
  }

  // STEP 3: Apply pagination to grouped structure
  Map<String, List<SmsMessage>> get _pagedGroupedTransactions {
    final allGrouped = _groupedByMerchant;
    final merchantNames = _merchantNames;
    
    // Flatten to calculate total transactions
    final flatList = <SmsMessage>[];
    for (final merchant in merchantNames) {
      flatList.addAll(allGrouped[merchant] ?? []);
    }

    // Calculate pagination range
    final start = _currentPage * _pageSize;
    if (start >= flatList.length) return {};

    final end = (start + _pageSize) > flatList.length
        ? flatList.length
        : (start + _pageSize);
    
    final pagedFlat = flatList.sublist(start, end);

    // Re-group the paged transactions
    final pagedGrouped = <String, List<SmsMessage>>{};
    for (final msg in pagedFlat) {
      final sender = (msg.sender ?? '').toLowerCase();
      final body = (msg.body ?? '').toLowerCase();
      final merchant = _smsService.matchMerchant(sender, body) ?? 'others';
      (pagedGrouped[merchant] ??= <SmsMessage>[]).add(msg);
    }

    return pagedGrouped;
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
      _currentPage = 0; // Reset to first page when month changes
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
          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: homeTabs.map((tab) {
              final isActive = _activeTab == tab.value;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: ChoiceChip(
                    label: Text(
                      tab.name,
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.2,
                        color: isActive ? Colors.white : Colors.grey[700],
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    selected: isActive,
                    onSelected: (_) {
                      setState(() {
                        _activeTab = tab.value;
                      });
                    },
                    selectedColor: AppTheme.linkPurple,
                    backgroundColor: Colors.grey[100]!,
                    shadowColor: Colors.black.withOpacity(0.15),
                    elevation: isActive ? 4 : 0,
                    pressElevation: 6,
                    showCheckmark: false,
                    side: BorderSide(
                      color: isActive ? AppTheme.linkPurple : Colors.grey[300]!,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Show appropriate view based on active tab
          Expanded(
            child: _activeTab == 'transactions'
                ? TransactionsView(
                    txLoading: _txLoading,
                    txError: _txError,
                    groupedTransactions: _pagedGroupedTransactions,
                    filteredCount: _filteredByMonth.length,
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    monthKeys: _monthKeys,
                    selectedMonthKey: _selectedMonthKey,
                    onMonthChanged: _onMonthChanged,
                    goNextPage: _goNextPage,
                    goPrevPage: _goPrevPage,
                    fmtDateTime: _fmtDateTime,
                  )
                : TrendsView(
                    transactions: allTransactions,
                  ),
          ),
        ],
      ),
    );
  }
}
