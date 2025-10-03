import 'package:flutter/material.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:intl/intl.dart';


class MonthlyExpenseView extends StatelessWidget {
  final Map<String, MonthlySummary> monthlySummaries;


  const MonthlyExpenseView({Key? key, required this.monthlySummaries}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final keys = monthlySummaries.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: keys.length,
      itemBuilder: (context, idx) {
        final key = keys[idx];
        final summary = monthlySummaries[key]!;
        final monthLabel = _formatMonth(key);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            title: Text('$monthLabel — Debit: ${summary.totalDebit().toStringAsFixed(2)} | Credit: ${summary.totalCredit().toStringAsFixed(2)}'),
            children: summary.transactions.map((t) {
              return ListTile(
                title: Text(t.sender),
                subtitle: Text(t.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(t.amount != null ? t.amount!.toStringAsFixed(2) : '-'),
              );
            }).toList(),
          ),
        );
      },
    );
  }


  String _formatMonth(String key) {
    try {
      final dt = DateFormat('yyyy-MM').parse(key);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return key;
    }
  }
}