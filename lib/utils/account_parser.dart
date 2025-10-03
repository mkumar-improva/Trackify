class AccountParser {
  static String inferInstitution(String sender, String body) {
    if (sender.isEmpty) {
      final bankMatch = RegExp(r'(?:from|by)\s+([A-Z][A-Za-z& ]{2,20})')
          .firstMatch(body);
      if (bankMatch != null) {
        return bankMatch.group(1)!.trim();
      }
      return 'Unknown Bank';
    }

    final cleaned = sender
        .replaceAll(RegExp('[^A-Za-z]'), ' ')
        .split(' ')
        .where((chunk) => chunk.isNotEmpty)
        .map((chunk) => chunk.toUpperCase())
        .toList();

    if (cleaned.isEmpty) return 'Unknown Bank';

    final bankAliases = <String, String>{
      'HDFC': 'HDFC Bank',
      'ICICI': 'ICICI Bank',
      'SBI': 'State Bank of India',
      'AXIS': 'Axis Bank',
      'KOTAK': 'Kotak Bank',
      'YESBANK': 'Yes Bank',
      'INDUSB': 'IndusInd Bank',
      'FEDBNK': 'Federal Bank',
      'PNB': 'Punjab National Bank',
      'UBI': 'Union Bank',
      'BOB': 'Bank of Baroda',
    };

    for (final chunk in cleaned) {
      if (bankAliases.containsKey(chunk)) return bankAliases[chunk]!;
    }

    return cleaned.first[0] + cleaned.first.substring(1).toLowerCase();
  }

  static String? extractAccountSuffix(String body) {
    final normalized = body.replaceAll('\n', ' ');
    final patterns = <RegExp>[
      RegExp(r'(?:account|a/c|ac)\s*(?:no|number|ending)?\s*[Xx*]*\s*(\d{4,})'),
      RegExp(r'ending\s*\*?\s*(\d{4,})'),
      RegExp(r'\*{2,}(\d{4})'),
      RegExp(r'[Xx]{2,}(\d{4})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final suffix = match.group(match.groupCount) ?? match.group(1);
        if (suffix != null && suffix.length >= 4) {
          return suffix.substring(suffix.length - 4);
        }
      }
    }
    return null;
  }

  static String? extractCounterparty(String body) {
    final normalized = body.replaceAll('\n', ' ');
    final upiMatch =
        RegExp(r'(?:to|from)\s+([\w\.\-]{3,}@\w{3,})', caseSensitive: false)
            .firstMatch(normalized);
    if (upiMatch != null) return upiMatch.group(1);

    final nameMatch =
        RegExp(r'(?:to|from)\s+([A-Z][A-Za-z ]{2,})').firstMatch(normalized);
    if (nameMatch != null) {
      final value = nameMatch.group(1)!.trim();
      if (!value.toLowerCase().contains('account')) return value;
    }

    return null;
  }
}
