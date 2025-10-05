import 'package:flutter/material.dart';
import 'package:u_credit_card/u_credit_card.dart';
import 'package:trackify/types/card_theme.dart';
import 'package:trackify/utils/card_utils.dart';

class CardPreview extends StatelessWidget {
  final String cardHolder;
  final String cardNumber;
  final String validThru;
  final String cvv;
  final String? brand;
  final CardThemeColors theme;
  final bool isDebitCard;

  const CardPreview({
    super.key,
    required this.cardHolder,
    required this.cardNumber,
    required this.validThru,
    required this.cvv,
    required this.brand,
    required this.theme,
    required this.isDebitCard,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CreditCardUi(
        width: 300,
        cardHolderFullName: cardHolder,
        cardNumber: cardNumber,
        showValidFrom: false,
        validThru: validThru,
        cvvNumber: cvv,
        topLeftColor: theme.topLeft,
        bottomRightColor: theme.bottomRight,
        placeNfcIconAtTheEnd: true,
        cardType: isDebitCard ? CardType.debit : CardType.credit,
        cardProviderLogo: brandLogo(brand),
        cardProviderLogoPosition: CardProviderLogoPosition.left,
        showBalance: false,
        autoHideBalance: true,
      ),
    );
  }
}
