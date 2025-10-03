class AmountParser {
  static double? extractAmountNearKeyword(String body, int keywordIndex) {
    final currencyPattern = RegExp(
      r'(?:₹|rs\.?|inr)\s*[:\-]?\s*([0-9]{1,3}(?:[,][0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final simpleNumberPattern = RegExp(
      r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
    );

    final currencyMatches = currencyPattern.allMatches(body).toList();
    RegExpMatch? chosen;
    if (currencyMatches.isNotEmpty) {
      chosen = _closestMatch(currencyMatches, keywordIndex);
    } else {
      final plainMatches = simpleNumberPattern.allMatches(body).toList();
      final filtered = plainMatches.where((m) {
        final before = m.start > 0 ? body[m.start - 1] : ' ';
        final after = m.end < body.length ? body[m.end] : ' ';
        if (before == '/' ||
            after == '/' ||
            before == '-' ||
            after == '-' ||
            before == ':' ||
            after == ':')
          return false;

        final contextStart = m.start - 8 >= 0
            ? body.substring(m.start - 8, m.start).toLowerCase()
            : body.substring(0, m.start).toLowerCase();
        if (contextStart.contains('ending') ||
            contextStart.contains('a/c') ||
            contextStart.contains('ac') ||
            contextStart.contains('account') ||
            contextStart.contains('card'))
          return false;

        final token = m.group(1) ?? '';
        if (token.replaceAll(',', '').split('.').first.length <= 1) {
          return token.replaceAll(',', '').length > 1;
        }
        return true;
      }).toList();

      if (filtered.isNotEmpty) chosen = _closestMatch(filtered, keywordIndex);
    }

    if (chosen == null) return null;

    var raw = chosen.group(1)!;
        raw = raw.replaceAll(',', '').replaceAll(RegExp('[^\\d.]'), '');
    try {
      return double.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static RegExpMatch? _closestMatch(
    List<RegExpMatch> matches,
    int keywordIndex,
  ) {
    if (matches.isEmpty) return null;
    RegExpMatch best = matches.first;
    double bestDist = ((best.start + best.end) / 2 - keywordIndex).abs();
    for (final m in matches.skip(1)) {
      final dist = ((m.start + m.end) / 2 - keywordIndex).abs();
      if (dist < bestDist) {
        best = m;
        bestDist = dist;
      }
    }
    return best;
  }
}
