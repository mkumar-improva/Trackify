import 'package:flutter/material.dart';
import 'package:trackify/components/card/add_bank_form.dart';
import 'package:trackify/components/card/add_card_form.dart';

class AddMethodSheet extends StatefulWidget {
  const AddMethodSheet({super.key});

  @override
  State<AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends State<AddMethodSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Payment Method',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    // color: Colors.white,
                    // borderRadius: BorderRadius.circular(10),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey[600],
                  tabs: const [
                    Tab(text: 'Card'),
                    Tab(text: 'Bank'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 430,
              child: TabBarView(
                controller: _tab,
                children: const [
                  AddCardForm(),
                  AddBankForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
