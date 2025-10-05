import 'package:flutter/material.dart';
import 'package:trackify/types/payment_method.dart';
import 'package:u_credit_card/u_credit_card.dart';

class CardPreview extends StatelessWidget {
  final PaymentMethod method;
  final double width;
  const CardPreview({super.key, required this.method, this.width = 300.0});

  String _mask(String? number) {
    if (number == null || number.isEmpty) return '•••• •••• •••• ••••';
    final digits = number.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 4) return '••••';
    final last4 = digits.substring(digits.length - 4);
    return '•••• •••• •••• $last4';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: CreditCardUi(
          width: width,
          cardHolderFullName: method.holder ?? 'Card Holder',
          cardNumber: _mask(method.last4),
          validThru: '${method.expiryMonth}/${method.expiryYear}' ?? 'MM/YY',
          cvvNumber: '***',
        ),
      ),
    );
  }
}
