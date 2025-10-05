import 'package:flutter/material.dart';
import 'package:trackify/components/card/add_method_sheet.dart';
import 'package:trackify/components/card/add_payment_form.dart';
import 'package:trackify/components/card/bank_account_tile.dart';
import 'package:trackify/components/card/card_preview.dart';
import 'package:trackify/components/card/dismiss_background.dart';
import 'package:trackify/components/card/empt_state.dart';
import 'package:trackify/components/card/payment_store.dart';
import 'package:trackify/components/card/section_title.dart';
import 'package:trackify/types/card_theme.dart';
import 'package:trackify/types/payment_method.dart';

class ManageCardsScreen extends StatefulWidget {
  const ManageCardsScreen({Key? key}) : super(key: key);

  @override
  State<ManageCardsScreen> createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  final PaymentStore store = PaymentStore();
  bool _loading = true;

  @override
  void initState() {
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
                  const SectionTitle('Cards'),
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
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            _onUpdate(c);
                          },
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
                if (cards.isNotEmpty || banks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Tip: Swipe left on an item to remove.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
    );
  }
}
