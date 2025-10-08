import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:trackify/components/empty_state.dart';


class TransactionsView extends StatelessWidget {
  final bool txLoading;
  final String? txError;
  final List<SmsMessage> paged;
  final List<SmsMessage> filteredByMonth;
  final int currentPage;
  final int totalPages;
  final List<String> monthKeys;
  final String? selectedMonthKey;
  final Function(String?) onMonthChanged;
  final VoidCallback goNextPage;
  final VoidCallback goPrevPage;
  final String Function(DateTime) fmtDateTime;


  const TransactionsView({
    super.key,
    required this.txLoading,
    required this.txError,
    required this.paged,
    required this.filteredByMonth,
    required this.currentPage,
    required this.totalPages,
    required this.monthKeys,
    required this.selectedMonthKey,
    required this.onMonthChanged,
    required this.goNextPage,
    required this.goPrevPage,
    required this.fmtDateTime,
  });


  String _labelFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]) ?? 1970;
    final month = int.tryParse(parts[1]) ?? 1;
    return DateFormat('MMM yyyy').format(DateTime(year, month));
  }


  @override
  Widget build(BuildContext context) {
    if (txLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }


    if (txError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          "Could not load transactions:\n$txError",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }


    if (filteredByMonth.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              "No transactions found for this filter",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }


    return Column(
      children: [
        // Single Row Filter and Pagination Controls
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month Filter Dropdown
                if (monthKeys.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMonthKey,
                        isDense: true,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'All months',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: Colors.grey,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'All months',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ...monthKeys.map(
                            (k) => DropdownMenuItem<String>(
                              value: k,
                              child: Text(
                                _labelFromKey(k),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: onMonthChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],


                // Transaction Count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${filteredByMonth.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(width: 12),


                // Page Info
                Text(
                  '${currentPage + 1}/${totalPages}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),


                const SizedBox(width: 8),


                // Previous Button
                IconButton(
                  onPressed: currentPage == 0 ? null : goPrevPage,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: currentPage == 0
                        ? Colors.grey.shade200
                        : Colors.white,
                    foregroundColor: currentPage == 0
                        ? Colors.grey.shade400
                        : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),


                const SizedBox(width: 4),


                // Next Button
                IconButton(
                  onPressed:
                      currentPage >= totalPages - 1 ? null : goNextPage,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: currentPage >= totalPages - 1
                        ? Colors.grey.shade200
                        : Colors.white,
                    foregroundColor: currentPage >= totalPages - 1
                        ? Colors.grey.shade400
                        : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),


        const SizedBox(height: 8),


        // Paged Transaction List
        Expanded(
          child: ListView.separated(
            itemCount: paged.length,
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final msg = paged[i];
              final body = (msg.body ?? '').trim();
              final sender = (msg.sender ?? '').trim();
              final when = msg.date ?? DateTime.now();


              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  dense: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue.shade700,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    body.isEmpty ? '(no message body)' : body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        sender.isEmpty ? 'Unknown' : sender,
                        fmtDateTime(when),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
