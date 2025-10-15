import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackify/components/card/payment_store.dart';
import 'package:trackify/screens/login_page_v2.dart';
import 'package:trackify/theme/app_theme.dart';

class TrackifyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final VoidCallback onRefreshPressed;
  final PaymentStore paymentStore;
  final int selectedCardIndex;
  final Function(int) onCardChanged;
  final bool showCardDropdown;

  const TrackifyAppBar({
    super.key,
    required this.titleText,
    required this.onRefreshPressed,
    required this.paymentStore,
    required this.selectedCardIndex,
    required this.onCardChanged,
    this.showCardDropdown = false,
  });

  void _onLogoutPressed(BuildContext context) async {
    final pref = await SharedPreferences.getInstance();
    pref.setBool("isLoggedIn", false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Widget _buildAppBarStyleDropdown(BuildContext context) {
    if (paymentStore.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCard = paymentStore.items[selectedCardIndex];
    final bankName = selectedCard.bankName ?? 'Card ${selectedCardIndex + 1}';
    final last4 = selectedCard.last4;

    return GestureDetector(
      onTap: () => _showCardBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card, color: Colors.black, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          bankName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                        size: 18,
                      ),
                    ],
                  ),
                  if (last4 != null)
                    Text(
                      '**** $last4',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Select Card',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Card list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: paymentStore.items.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  final card = paymentStore.items[index];
                  final isSelected = index == selectedCardIndex;
                  final bankName = card.bankName ?? 'Card ${index + 1}';
                  final last4 = card.last4;

                  return InkWell(
                    onTap: () {
                      onCardChanged(index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.linkPurple.withOpacity(0.05)
                            : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected
                                ? AppTheme.linkPurple
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.linkPurple.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.credit_card,
                              color: isSelected
                                  ? AppTheme.linkPurple
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bankName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.linkPurple
                                        : Colors.grey[800],
                                  ),
                                ),
                                if (last4 != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '**** **** **** $last4',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.linkPurple,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: showCardDropdown
          ? _buildAppBarStyleDropdown(context)
          : Text(
              titleText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
      actions: [
        IconButton(
          onPressed: onRefreshPressed,
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}
