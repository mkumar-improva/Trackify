import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:trackify/components/card/card_preview.dart';
import 'package:trackify/components/card/payment_store.dart';
import 'package:trackify/components/empty_state.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/theme/app_theme.dart';

class AccountSummary extends StatefulWidget {
  const AccountSummary({super.key});

  @override
  State<AccountSummary> createState() => _AccountSummaryState();
}

class _AccountSummaryState extends State<AccountSummary> {
  final SmsService _smsService = SmsService();
  final PaymentStore store = PaymentStore();

  List<SmsMessage> transactions = [];
  int selectedCard = 0;
  bool _loading = false;

  // transactions fetch state
  bool _txLoading = false;
  String? _txError;

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
    });
    try {
      final senders = store.items[selectedCard].senders ?? "";
      debugPrint('${senders}');
      final msgs = await _smsService.getAllSmsFromSender(senders);
      debugPrint('${msgs}');
      if (!mounted) return;
      setState(() {
        transactions = msgs;
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
      selectedCard = index; // fixed assignment
    });
    await _loadTransactionsForSelected();
  }

  String _fmt(DateTime dt) => DateFormat('dd MMM, hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final items = store.items;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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

        const SizedBox(height: 16),
        Center(
          child: Text(
            "Selected card: ${items[selectedCard].bankName ?? 'N/A'}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          "Transactions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // Transactions states: loading / error / empty / list
        if (_txLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_txError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Could not load transactions:\n$_txError",
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: const [
                  Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "No transactions found for this account",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
          // Build the list based on the transactions
            SizedBox(
              height: 500,
              child: SingleChildScrollView(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final msg = transactions[i];
                    final body = (msg.body ?? '').trim();
                    final sender = (msg.sender ?? '').trim();
                    final when = msg.date ?? DateTime.now();
                
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        dense: false,
                        leading: const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.account_balance_wallet),
                        ),
                        title: Text(
                          body.isEmpty ? '(no message body)' : body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [sender.isEmpty ? 'Unknown' : sender, _fmt(when)]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      ],
    );
  }
}
