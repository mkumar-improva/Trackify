import 'package:flutter/material.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:intl/intl.dart';

class MonthlyExpenseView extends StatelessWidget {
  const MonthlyExpenseView({Key? key, required this.monthlySummaries}) : super(key: key);

  final Map<String, MonthlySummary> monthlySummaries;

  @override
  Widget build(BuildContext context) {
    final sortedMonths = monthlySummaries.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final monthKey = sortedMonths[index];
        final summary = monthlySummaries[monthKey]!;
        final monthName = DateFormat('MMMM yyyy').format(DateTime.parse('${monthKey}-01'));

        return ExpansionTile(
          title: Text(monthName),
          subtitle: Text('Incoming: ₹${summary.totalCredit.toStringAsFixed(2)} • Outgoing: ₹${summary.totalDebit.toStringAsFixed(2)}'),
          children: summary.transactions.map((t) {
            final amountText = t.amount != null ? t.amount!.toStringAsFixed(2) : 'Unknown';
            return ListTile(
              leading: Icon(t.type == 'DEBIT' ? Icons.arrow_upward : Icons.arrow_downward, color: t.type == 'DEBIT' ? Colors.red : Colors.green),
              title: Text('${t.type} • ₹ $amountText'),
              subtitle: Text(DateFormat('dd MMM, hh:mm a').format(t.date)),
            );
          }).toList(),
        );
      },
    );
  }
}