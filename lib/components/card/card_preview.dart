import 'package:flutter/material.dart';
import 'package:trackify/components/app_logo.dart';
import 'package:trackify/types/card_theme.dart';
import 'package:trackify/types/payment_method.dart';
import 'package:trackify/utils/card_utils.dart';
import 'package:u_credit_card/u_credit_card.dart';

class CardPreview extends StatelessWidget {
  final PaymentMethod method;
  final double width;
  final bool bankNameVisibility;
  const CardPreview({super.key, required this.method, this.width = 300.0, this.bankNameVisibility = false});

  String _mask(String? number) {
    if (number == null || number.isEmpty) return '•••• •••• •••• ••••';
    final digits = number.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 4) return '••••';
    final last4 = digits.substring(digits.length - 4);
    return '•••• •••• •••• $last4';
  }

  CardBrandOptions _brandStringToOption(String? brand) {
    if (brand == null || brand.isEmpty) return CardBrandOptions.auto;
    final b = brand.toLowerCase();
    if (b.contains('visa')) return CardBrandOptions.visa;
    if (b.contains('master')) return CardBrandOptions.mastercard;
    if (b.contains('amex') || b.contains('american')) return CardBrandOptions.amex;
    if (b.contains('rupay')) return CardBrandOptions.rupay;
    if (b.contains('discover')) return CardBrandOptions.discover;
    if (b.contains('maestro')) return CardBrandOptions.maestro;
    if (b.contains('other')) return CardBrandOptions.other;
    return CardBrandOptions.auto;
  }

  String _optionToBrandString(CardBrandOptions opt, String? fallback) {
    switch (opt) {
      case CardBrandOptions.visa:
        return 'Visa';
      case CardBrandOptions.mastercard:
        return 'Mastercard';
      case CardBrandOptions.amex:
        return 'Amex';
      case CardBrandOptions.rupay:
        return 'RuPay';
      case CardBrandOptions.discover:
        return 'Discover';
      case CardBrandOptions.maestro:
        return 'maestro';
      case CardBrandOptions.other:
        return 'Other';
      case CardBrandOptions.auto:
        return fallback ?? 'Card';
    }
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
        child: Column(
          children: [
            CreditCardUi(
              width: width,
              cardHolderFullName: method.holder ?? 'Card Holder',
              cardNumber: _mask(method.last4),
              validThru: '${method.expiryMonth}/${method.expiryYear}' ?? 'MM/YY',
              cvvNumber: '***',
              bottomRightColor: colorOptions[method.variant ?? 0].bottomRight,
              topLeftColor: colorOptions[method.variant ?? 0].topLeft,
              placeNfcIconAtTheEnd: true,
              cardProviderLogo: FlutterLogo(),
              cardProviderLogoPosition: CardProviderLogoPosition.left,
              cardType: method.cardType == "credit"
                  ? CardType.credit
                  : method.cardType == "debit"
                  ? CardType.debit
                  : CardType.other,
            ),
            if (bankNameVisibility) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${method.label}'),
              )
            ],
          ],
        )
      ),
    );
  }
}
