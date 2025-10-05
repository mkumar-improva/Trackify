import 'package:flutter/material.dart';

enum CardBrandOptions {
  auto,
  visa,
  mastercard,
  amex,
  discover,
  rupay,
  maestro,
  other,
}

extension CardBrandOptionsX on CardBrandOptions {
  String get label => switch (this) {
    CardBrandOptions.auto => 'Auto (detect)',
    CardBrandOptions.visa => 'VISA',
    CardBrandOptions.mastercard => 'Mastercard',
    CardBrandOptions.amex => 'Amex',
    CardBrandOptions.discover => 'Discover',
    CardBrandOptions.rupay => 'RuPay',
    CardBrandOptions.maestro => 'Maestro',
    CardBrandOptions.other => 'Other',
  };
}

String? detectBrand(String digits) {
  if (digits.isEmpty) return null;
  if (RegExp(r'^4').hasMatch(digits)) return 'VISA';
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'Mastercard';
  if (RegExp(r'^(34|37)').hasMatch(digits)) return 'Amex';
  if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) return 'Discover';
  if (RegExp(r'^(50|60|65|81|82)').hasMatch(digits)) return 'RuPay';
  if (RegExp(r'^(50|56|57|58)').hasMatch(digits)) return 'Maestro';
  return 'Card';
}

String? effectiveBrand({
  required CardBrandOptions dropdown,
  required String numberDigits,
}) {
  switch (dropdown) {
    case CardBrandOptions.auto:
      return detectBrand(numberDigits);
    case CardBrandOptions.other:
      return 'Card'; // generic
    case CardBrandOptions.visa:
      return 'VISA';
    case CardBrandOptions.mastercard:
      return 'Mastercard';
    case CardBrandOptions.amex:
      return 'Amex';
    case CardBrandOptions.discover:
      return 'Discover';
    case CardBrandOptions.rupay:
      return 'RuPay';
    case CardBrandOptions.maestro:
      return 'Maestro';
  }
}

Widget brandLogo(String? brand) {
  // Replace with your asset images if you have any.
  switch (brand) {
    case 'VISA':
    case 'Mastercard':
    case 'Amex':
    case 'RuPay':
    case 'Discover':
    case 'Maestro':
      return const Icon(Icons.credit_card);
    default:
      return const FlutterLogo();
  }
}

String maskAccount(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'XX••••';
  final last4 = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  return 'XX$last4';
}
