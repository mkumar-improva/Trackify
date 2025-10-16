import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';

class TransactionsView extends StatelessWidget {
  final bool txLoading;
  final String? txError;
  final Map<String, List<SmsMessage>> groupedTransactions;
  final int filteredCount;
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
    required this.groupedTransactions,
    required this.filteredCount,
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

  String _formatMerchantName(String key) {
    if (key == 'others') return 'Others';
    // Capitalize first letter and replace common abbreviations
    final formatted = key[0].toUpperCase() + key.substring(1);
    return formatted
        .replaceAll('amazonpay', 'Amazon Pay')
        .replaceAll('paytmmall', 'Paytm Mall')
        .replaceAll('tataneu', 'Tata Neu')
        .replaceAll('jiomart', 'JioMart')
        .replaceAll('bookmyshow', 'BookMyShow')
        .replaceAll('makemytrip', 'MakeMyTrip')
        .replaceAll('bigbasket', 'BigBasket');
  }

  Widget _getMerchantWidget(String merchant, Color color) {
    switch (merchant.toLowerCase()) {
      case 'swiggy':
        return Image.asset(
          'assets/images/swiggy_thumb.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'amazon':
      case 'amazonpay':
        return Image.asset(
          'assets/images/amazon.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'flipkart':
        return Image.asset(
          'assets/images/flipkart.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'zomato':
        return Image.asset(
          'assets/images/zomato.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'zepto':
        return Image.asset(
          'assets/images/zepto.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'blinkit':
        return Image.asset(
          'assets/images/blinkit.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'ajio':
        return Image.asset(
          'assets/images/ajio.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'meesho':
        return Image.asset(
          'assets/images/meesho.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'myntra':
        return Image.asset(
          'assets/images/myntra.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'nykaa':
        return Image.asset(
          'assets/images/nykaa.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'bigbasket':
        return Image.asset(
          'assets/images/bigbasket.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'jiomart':
        return Image.asset(
          'assets/images/jiomart.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'ola':
        return Image.asset(
          'assets/images/ola.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'uber':
        return Image.asset(
          'assets/images/uber.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case 'rapido':
        return Image.asset(
          'assets/images/rapido.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );

      default:
        return Icon(_getMerchantIcon(merchant), color: color, size: 22);
    }
  }

  IconData _getMerchantIcon(String merchant) {
    switch (merchant.toLowerCase()) {
      case 'bookmyshow':
        return Icons.movie;
      case 'makemytrip':
      case 'cleartrip':
      case 'irctc':
        return Icons.flight;
      case 'paytm':
      case 'gpay':
      case 'paytmmall':
        return Icons.payment;
      default:
        return Icons.store;
    }
  }

  Color _getMerchantColor(String merchant) {
    switch (merchant.toLowerCase()) {
      case 'swiggy':
        return Colors.orange;
      case 'zomato':
        return Colors.red;
      case 'amazon':
      case 'amazonpay':
        return Colors.orange.shade800;
      case 'flipkart':
        return Colors.blue;
      case 'ola':
      case 'uber':
        return Colors.black;
      default:
        return Colors.deepPurple;
    }
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

    if (groupedTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              selectedMonthKey != null
                  ? "No transactions found for ${_labelFromKey(selectedMonthKey!)}"
                  : "No transactions found",
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Get sorted merchant names (others at end)
    final merchantNames = groupedTransactions.keys.toList();
    merchantNames.sort((a, b) {
      if (a == 'others') return 1;
      if (b == 'others') return -1;
      return a.compareTo(b);
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter and Pagination Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Month Filter Dropdown - Takes flexible space
              if (monthKeys.isNotEmpty) ...[
                Flexible(
                  flex: 2,
                  child: Container(
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
                        isExpanded: true,
                        hint: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All months',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ...monthKeys.map(
                            (k) => DropdownMenuItem<String>(
                              value: k,
                              child: Text(
                                _labelFromKey(k),
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: onMonthChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Transaction Count Badge - Fixed minimal size
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$filteredCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Page Info - Compact
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${currentPage + 1}/$totalPages',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Previous Button - Compact
              InkWell(
                onTap: currentPage == 0 ? null : goPrevPage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentPage == 0
                        ? Colors.grey.shade200
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    size: 16,
                    color: currentPage == 0
                        ? Colors.grey.shade400
                        : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Next Button - Compact
              InkWell(
                onTap: currentPage >= totalPages - 1 ? null : goNextPage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentPage >= totalPages - 1
                        ? Colors.grey.shade200
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: currentPage >= totalPages - 1
                        ? Colors.grey.shade400
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Grouped Transaction List by Merchant
        Expanded(
          child: ListView.builder(
            itemCount: merchantNames.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, merchantIndex) {
              final merchant = merchantNames[merchantIndex];
              final txList = groupedTransactions[merchant] ?? [];
              final color = _getMerchantColor(merchant);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant Header

                  // Transactions for this merchant
                  ...txList.map((msg) {
                    final body = (msg.body ?? '').trim();
                    final sender = (msg.sender ?? '').trim();
                    final when = msg.date ?? DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
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
                          horizontal: 8,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: color.withOpacity(0.1),
                          child: _getMerchantWidget(merchant, color),
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
                  }).toList(),

                  const SizedBox(height: 16), // Space between groups
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
