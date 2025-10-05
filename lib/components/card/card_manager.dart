import 'package:flutter/material.dart';
import 'package:trackify/components/SenderPickerSheet.dart';
import 'package:trackify/components/card/add_method_sheet.dart';
import 'package:trackify/components/card/add_payment_form.dart';
import 'package:trackify/components/card/bank_account_tile.dart';
import 'package:trackify/components/card/card_preview.dart';
import 'package:trackify/components/card/dismiss_background.dart';
import 'package:trackify/components/card/empt_state.dart';
import 'package:trackify/components/card/payment_store.dart';
import 'package:trackify/components/card/section_title.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/types/card_theme.dart';
import 'package:trackify/types/payment_method.dart';

class ManageCardsScreen extends StatefulWidget {
  const ManageCardsScreen({Key? key}) : super(key: key);

  @override
  State<ManageCardsScreen> createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  final PaymentStore store = PaymentStore();
  final SmsService _smsService = SmsService();

  bool _loading = true;

  @override
 initState() {
    super.initState();
    store.addListener(_onStore);
    _init();
  }

  void _onStore() => setState(() {});
  Future<void> _init() async {
    await store.load();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  Future<void> _openAdd() async {
    PaymentMethod method = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPaymentForm()),
    );
    debugPrint('Method: $method');
    if (method != null) {
      await store.add(method);
    }
  }

  Future<void> _confirmDelete(PaymentMethod m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove?'),
        content: Text(
          m.type == PaymentType.card
              ? 'Remove this card?'
              : 'Remove this bank account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await store.remove(m.id);
    }
  }

  void _onUpdate(PaymentMethod m) async {
    final updated = await Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(builder: (_) => AddPaymentForm(existing: m)),
    );
    if (updated != null) {
      await store.update(updated);
    }
  }



  void _fetchAllSMSBasedOnCard(PaymentMethod method) async {
    List<String> keywords = [];

    if (method.label != null) {
      method.label.toString().split(" ").forEach((element) {
        if (element == null ||
            element.isEmpty ||
            element == method.bankName.toString().split(" ")[0])
          return;
        element = element.replaceAll("X", "");
        element = element.replaceAll("•", "");
        element = element.replaceAll("bank", "");
        keywords.add(element);
      });
    }
    final shortBank = (method.bankName?.length ?? 0) >= 3
        ? method.bankName!.substring(0, 3).toLowerCase()
        : "";

    List<String> senders = await _smsService.listAllSendersWithRelevantSms(
      keywords,
    );

    if (shortBank.isNotEmpty) {
      senders = senders.where((s) => s.contains(shortBank)).toList();
    }

    Set<String> initialSenders = {};

    method.senders.toString().split(",").forEach((element) {
      initialSenders.add(element);
    });

    final selected = await showSenderPickerBottomSheet(
      context,
      senders: senders,
      initialSelected: initialSenders, // optional
    );

    // Use the result
    if (selected != null && selected.length > 0) {
      final updated = method.copyWith(
        senders: selected.join(","),
      );
      debugPrint('Updated Method: ${updated.senders}');
      await store.update(updated);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<List<String>?> showSenderPickerBottomSheet(
    BuildContext context, {
    required List<String> senders,
    Set<String>? initialSelected,
    String title = 'Select Senders',
  }) {
    final uniqueSorted = senders.toSet().toList()..sort();

    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      showDragHandle: true,
      elevation: 10,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SenderPickerSheet(
        title: title,
        items: uniqueSorted,
        initiallySelected: initialSelected ?? {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = store.cards;
    final banks = store.banks;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Cards')),
      floatingActionButton: store.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : store.items.isEmpty
          ? EmptyState(onAdd: _openAdd)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (cards.isNotEmpty) ...[
                  const SectionTitle('Your Bank Accounts'),
                  if (cards.isNotEmpty || banks.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Tip: Swipe left on an item to remove.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ...cards.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(c.id),
                          background: const DismissBackground(),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (_) async {
                            await _confirmDelete(c);
                            return false; // we delete via dialog action
                          },
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.label),
                            subtitle: Text("${c.holder} - ${c.cardType}"),
                            leading: Icon(
                              Icons.credit_card,
                              color: colorOptions[c.variant ?? 0].bottomRight,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  child: const Icon(Icons.sms_rounded),
                                  onTap: () => _fetchAllSMSBasedOnCard(c),
                                ),
                                const SizedBox(width: 16),
                                InkWell(
                                  child: const Icon(
                                    Icons.edit_note_outlined,
                                    size: 30,
                                  ),
                                  onTap: () => _onUpdate(c),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (banks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const SectionTitle('Bank Accounts'),
                    const SizedBox(height: 8),
                    ...banks.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: ValueKey(b.id),
                          background: const DismissBackground(),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmDelete(b);
                            return false;
                          },
                          child: BankAccountTile(method: b),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
