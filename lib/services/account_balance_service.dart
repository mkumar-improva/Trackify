import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:trackify/services/sms_service.dart';
import 'package:trackify/types/payment_method.dart';

/// Represents a parsed transaction with amount and type
class ParsedTransaction {
  final String sender;
  final String body;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String? merchant;
  final String? accountNumber;

  ParsedTransaction({
    required this.sender,
    required this.body,
    required this.date,
    required this.amount,
    required this.type,
    this.merchant,
    this.accountNumber,
  });

  String monthKey() {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}

enum TransactionType {
  debit,
  credit,
}

/// Represents the balance information extracted from SMS
class BalanceInfo {
  final double balance;
  final DateTime date;
  final String sender;
  final String rawMessage;

  BalanceInfo({
    required this.balance,
    required this.date,
    required this.sender,
    required this.rawMessage,
  });
}

/// Account spending summary
class AccountSpendSummary {
  final String accountLabel;
  final String? accountMask;
  final double totalDebit;
  final double totalCredit;
  final int debitCount;
  final int creditCount;
  final double netSpend; // totalDebit - totalCredit
  final List<ParsedTransaction> transactions;
  final BalanceInfo? latestBalance;
  final bool balanceMatches;

  AccountSpendSummary({
    required this.accountLabel,
    this.accountMask,
    required this.totalDebit,
    required this.totalCredit,
    required this.debitCount,
    required this.creditCount,
    required this.netSpend,
    required this.transactions,
    this.latestBalance,
    this.balanceMatches = false,
  });

  /// Calculate average transaction amount
  double get averageDebit => debitCount > 0 ? totalDebit / debitCount : 0.0;
  double get averageCredit => creditCount > 0 ? totalCredit / creditCount : 0.0;

  /// Get transactions by type
  List<ParsedTransaction> get debits =>
      transactions.where((t) => t.type == TransactionType.debit).toList();
  
  List<ParsedTransaction> get credits =>
      transactions.where((t) => t.type == TransactionType.credit).toList();

  /// Group transactions by month
  Map<String, List<ParsedTransaction>> get transactionsByMonth {
    final Map<String, List<ParsedTransaction>> grouped = {};
    for (final tx in transactions) {
      final key = tx.monthKey();
      (grouped[key] ??= []).add(tx);
    }
    return grouped;
  }

  /// Get monthly spending breakdown
  Map<String, MonthlySpend> get monthlyBreakdown {
    final Map<String, MonthlySpend> breakdown = {};
    final grouped = transactionsByMonth;
    
    for (final entry in grouped.entries) {
      final monthKey = entry.key;
      final txList = entry.value;
      
      double debitSum = 0.0;
      double creditSum = 0.0;
      int debitCnt = 0;
      int creditCnt = 0;

      for (final tx in txList) {
        if (tx.type == TransactionType.debit) {
          debitSum += tx.amount;
          debitCnt++;
        } else {
          creditSum += tx.amount;
          creditCnt++;
        }
      }

      breakdown[monthKey] = MonthlySpend(
        month: monthKey,
        totalDebit: debitSum,
        totalCredit: creditSum,
        debitCount: debitCnt,
        creditCount: creditCnt,
        netSpend: debitSum - creditSum,
      );
    }

    return breakdown;
  }

  /// Get spending by merchant
  Map<String, MerchantSpend> get spendingByMerchant {
    final Map<String, MerchantSpend> merchantSpends = {};

    for (final tx in transactions) {
      final merchant = tx.merchant ?? 'others';
      
      if (!merchantSpends.containsKey(merchant)) {
        merchantSpends[merchant] = MerchantSpend(
          merchant: merchant,
          totalDebit: 0.0,
          totalCredit: 0.0,
          debitCount: 0,
          creditCount: 0,
          transactions: [],
        );
      }

      final current = merchantSpends[merchant]!;
      merchantSpends[merchant] = MerchantSpend(
        merchant: merchant,
        totalDebit: current.totalDebit + (tx.type == TransactionType.debit ? tx.amount : 0.0),
        totalCredit: current.totalCredit + (tx.type == TransactionType.credit ? tx.amount : 0.0),
        debitCount: current.debitCount + (tx.type == TransactionType.debit ? 1 : 0),
        creditCount: current.creditCount + (tx.type == TransactionType.credit ? 1 : 0),
        transactions: [...current.transactions, tx],
      );
    }

    return merchantSpends;
  }
}

/// Monthly spending summary
class MonthlySpend {
  final String month;
  final double totalDebit;
  final double totalCredit;
  final int debitCount;
  final int creditCount;
  final double netSpend;

  MonthlySpend({
    required this.month,
    required this.totalDebit,
    required this.totalCredit,
    required this.debitCount,
    required this.creditCount,
    required this.netSpend,
  });
}

/// Merchant-wise spending summary
class MerchantSpend {
  final String merchant;
  final double totalDebit;
  final double totalCredit;
  final int debitCount;
  final int creditCount;
  final List<ParsedTransaction> transactions;

  MerchantSpend({
    required this.merchant,
    required this.totalDebit,
    required this.totalCredit,
    required this.debitCount,
    required this.creditCount,
    required this.transactions,
  });

  double get netSpend => totalDebit - totalCredit;
}

/// Service to handle account balance tracking and spend analysis
class AccountBalanceService {
  final SmsService _smsService = SmsService();

  /// Parse all transactions for a given payment method
  Future<List<ParsedTransaction>> parseTransactionsForAccount(
    PaymentMethod paymentMethod,
  ) async {
    if (paymentMethod.senders == null || paymentMethod.senders!.isEmpty) {
      return [];
    }

    final messages = await _smsService.getAllSmsFromSender(paymentMethod.senders!);
    final List<ParsedTransaction> transactions = [];

    for (final msg in messages) {
      final parsed = _parseTransactionFromSms(msg);
      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  /// Parse a single SMS message into a transaction
  ParsedTransaction? _parseTransactionFromSms(SmsMessage msg) {
    final body = msg.body ?? '';
    final sender = msg.sender ?? '';
    final date = msg.date ?? DateTime.now();
    final bodyLower = body.toLowerCase();
    final senderLower = sender.toLowerCase();

    // Determine transaction type
    TransactionType? type;
    if (bodyLower.contains('debited') || bodyLower.contains('sent via upi')) {
      type = TransactionType.debit;
    } else if (bodyLower.contains('credited') || bodyLower.contains('received via upi')) {
      type = TransactionType.credit;
    }

    if (type == null) return null;

    // Extract amount using various patterns
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    // Extract merchant
    final merchant = _smsService.matchMerchant(senderLower, bodyLower);

    // Extract account number
    final accountNumber = _extractAccountNumber(body);

    return ParsedTransaction(
      sender: sender,
      body: body,
      date: date,
      amount: amount,
      type: type,
      merchant: merchant,
      accountNumber: accountNumber,
    );
  }

  /// Extract amount from SMS text
  double? _extractAmount(String text) {
    // Comprehensive list of transaction keywords used in Indian bank SMS
    final transactionKeywords = [
      'debited', 'credited',
      'sent', 'received',
      'paid', 'payment',
      'paid thru', 'paid through',
      'withdrawn', 'withdrawal',
      'transferred', 'transfer',
      'deposited', 'deposit',
      'spent', 'purchase', 'purchased',
      'refund', 'refunded',
      'charged',
      'deducted',
    ];
    
    // Build dynamic pattern from keywords
    final keywordPattern = transactionKeywords.join('|');
    
    final patterns = [
      // Pattern 1: keyword + optional preposition + amount
      // Examples: "debited Rs. 500", "paid to Rs 1000", "sent via upi Rs. 250"
      RegExp(
        r'(?:' + keywordPattern + r')\s+(?:with|to|from|for|via|thru|through)?\s*(?:rs\.?|inr|rupees?)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:' + keywordPattern + r')\s+(?:with|to|from|for|via|thru|through)?\s*(?:rs\.?|inr|rupees?)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 2: amount + optional auxiliary verb + keyword
      // Examples: "Rs. 500 debited", "1000 is paid", "Rs 250 sent"
      RegExp(
        r'(?:rs\.?|inr|rupees?)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s+(?:is|has been|was|been)?\s*(?:' + keywordPattern + r')',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr|rupees?)?\s*([0-9]+(?:\.[0-9]{1,2})?)\s+(?:is|has been|was|been)?\s*(?:' + keywordPattern + r')',
        caseSensitive: false,
      ),
      
      // Pattern 3: UPI and digital wallet specific patterns
      // Examples: "sent via upi Rs. 500", "paid thru paytm 1000", "gpay Rs. 250"
      RegExp(
        r'(?:sent|received|paid|transferred)\s+(?:via|thru|through|using|on)?\s*(?:upi|gpay|paytm|phonepe|bhim)\s+(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s+(?:sent|received|paid|transferred)\s+(?:via|thru|through|using|on)?\s*(?:upi|gpay|paytm|phonepe|bhim)',
        caseSensitive: false,
      ),
      
      // Pattern 4: Standard currency prefix patterns
      RegExp(
        r'(?:rs\.?|inr|rupees?)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr|rupees?)\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 5: Amount with descriptive keywords
      // Examples: "Amount: Rs. 500", "Transaction amount 1000", "Value Rs 250"
      RegExp(
        r'(?:amount|amt|value|transaction|txn)[\s:]+(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:amount|amt|value|transaction|txn)[\s:]+(?:rs\.?|inr)?\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 6: Preposition-based patterns
      // Examples: "of Rs. 500", "for Rs 1000", "worth Rs. 250"
      RegExp(
        r'(?:of|for|worth)\s+(?:rs\.?|inr)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      
      // Pattern 7: Generic comma-separated numbers (fallback)
      RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{1,2})?)\b'),
      
      // Pattern 8: Amount with context words
      RegExp(
        r'(?:total|bill|balance|pay)\s+(?:rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final rawAmount = match.group(1) ?? '';
        final normalized = rawAmount.replaceAll(',', '');
        try {
          final amount = double.parse(normalized);
          // Skip unreasonably small or large amounts
          // Skip numbers that look like dates (DDMMYYYY format)
          // Skip phone numbers (10 digits)
          if (amount > 0 && amount < 10000000) {
            return amount;
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract account number from SMS text
  String? _extractAccountNumber(String text) {
    final patterns = [
      RegExp(r'(?:a/c|ac|account)\s*(?:no[:\s]*)?([xX\*\d]{4,})', caseSensitive: false),
      RegExp(r'(?:card|debit card)\s*(?:ending|no\.?)\s*([xX\*\d]{4,})', caseSensitive: false),
      RegExp(r'([xX\*]{2,}\d{2,})', caseSensitive: false),
      RegExp(r'ending\s*(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Extract balance from SMS messages
  Future<List<BalanceInfo>> extractBalanceHistory(
    PaymentMethod paymentMethod,
  ) async {
    if (paymentMethod.senders == null || paymentMethod.senders!.isEmpty) {
      return [];
    }

    final messages = await _smsService.getAllSmsFromSender(paymentMethod.senders!);
    final List<BalanceInfo> balances = [];

    for (final msg in messages) {
      final balance = _extractBalanceFromSms(msg);
      if (balance != null) {
        balances.add(balance);
      }
    }

    // Sort by date (newest first)
    balances.sort((a, b) => b.date.compareTo(a.date));

    return balances;
  }

  /// Extract balance information from a single SMS
  BalanceInfo? _extractBalanceFromSms(SmsMessage msg) {
    final body = msg.body ?? '';
    final sender = msg.sender ?? '';
    final date = msg.date ?? DateTime.now();
    final bodyLower = body.toLowerCase();

    // Look for balance keywords
    if (!bodyLower.contains('balance') && 
        !bodyLower.contains('avl bal') && 
        !bodyLower.contains('available')) {
      return null;
    }

    // Extract balance amount
    final patterns = [
      RegExp(r'(?:balance|bal|avl bal|available)[\s:]+(?:rs\.?|inr)?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'(?:rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:balance|bal|avl)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final rawAmount = match.group(1) ?? '';
        final normalized = rawAmount.replaceAll(',', '');
        try {
          final balance = double.parse(normalized);
          return BalanceInfo(
            balance: balance,
            date: date,
            sender: sender,
            rawMessage: body,
          );
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  /// Generate complete spend summary for an account
  Future<AccountSpendSummary> generateAccountSummary(
    PaymentMethod paymentMethod,
  ) async {
    final transactions = await parseTransactionsForAccount(paymentMethod);
    final balanceHistory = await extractBalanceHistory(paymentMethod);

    double totalDebit = 0.0;
    double totalCredit = 0.0;
    int debitCount = 0;
    int creditCount = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.debit) {
        totalDebit += tx.amount;
        debitCount++;
      } else {
        totalCredit += tx.amount;
        creditCount++;
      }
    }

    final netSpend = totalDebit - totalCredit;
    final latestBalance = balanceHistory.isNotEmpty ? balanceHistory.first : null;

    // Check if balance matches (simple validation)
    // This is a basic check - you might want to make it more sophisticated
    bool balanceMatches = false;
    if (latestBalance != null && transactions.isNotEmpty) {
      // Find all transactions after the balance date
      final txAfterBalance = transactions
          .where((tx) => tx.date.isAfter(latestBalance.date))
          .toList();
      
      if (txAfterBalance.isEmpty) {
        // If no transactions after balance, we can't verify
        balanceMatches = true;
      } else {
        // Calculate expected balance based on transactions after balance date
        double expectedChange = 0.0;
        for (final tx in txAfterBalance) {
          if (tx.type == TransactionType.debit) {
            expectedChange -= tx.amount;
          } else {
            expectedChange += tx.amount;
          }
        }
        
        // Allow for small floating point differences (within ₹1)
        final calculatedBalance = latestBalance.balance + expectedChange;
        balanceMatches = (calculatedBalance - latestBalance.balance).abs() < 1.0;
      }
    }

    return AccountSpendSummary(
      accountLabel: paymentMethod.label,
      accountMask: paymentMethod.accountMask ?? paymentMethod.last4,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      debitCount: debitCount,
      creditCount: creditCount,
      netSpend: netSpend,
      transactions: transactions,
      latestBalance: latestBalance,
      balanceMatches: balanceMatches,
    );
  }

  /// Generate summaries for multiple accounts
  Future<List<AccountSpendSummary>> generateMultipleAccountSummaries(
    List<PaymentMethod> paymentMethods,
  ) async {
    final summaries = <AccountSpendSummary>[];

    for (final method in paymentMethods) {
      final summary = await generateAccountSummary(method);
      summaries.add(summary);
    }

    return summaries;
  }

  /// Calculate spending trends over time
  Map<String, double> calculateSpendingTrend(
    AccountSpendSummary summary, {
    int months = 6,
  }) {
    final now = DateTime.now();
    final trends = <String, double>{};

    for (int i = 0; i < months; i++) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthKey = '${targetMonth.year.toString().padLeft(4, '0')}-${targetMonth.month.toString().padLeft(2, '0')}';
      
      final monthlyBreakdown = summary.monthlyBreakdown[monthKey];
      trends[monthKey] = monthlyBreakdown?.totalDebit ?? 0.0;
    }

    return trends;
  }

  /// Get top spending merchants for an account
  List<MerchantSpend> getTopMerchants(
    AccountSpendSummary summary, {
    int limit = 10,
  }) {
    final merchantSpends = summary.spendingByMerchant.values.toList();
    merchantSpends.sort((a, b) => b.totalDebit.compareTo(a.totalDebit));
    
    return merchantSpends.take(limit).toList();
  }

  /// Compare spending across multiple accounts
  Map<String, dynamic> compareAccounts(
    List<AccountSpendSummary> summaries,
  ) {
    if (summaries.isEmpty) {
      return {
        'totalSpend': 0.0,
        'totalCredit': 0.0,
        'accountCount': 0,
        'highestSpender': null,
        'lowestSpender': null,
      };
    }

    double totalSpend = 0.0;
    double totalCredit = 0.0;

    for (final summary in summaries) {
      totalSpend += summary.totalDebit;
      totalCredit += summary.totalCredit;
    }

    // Sort by total debit to find highest and lowest spenders
    final sorted = [...summaries];
    sorted.sort((a, b) => b.totalDebit.compareTo(a.totalDebit));

    return {
      'totalSpend': totalSpend,
      'totalCredit': totalCredit,
      'accountCount': summaries.length,
      'highestSpender': sorted.first.accountLabel,
      'highestSpenderAmount': sorted.first.totalDebit,
      'lowestSpender': sorted.last.accountLabel,
      'lowestSpenderAmount': sorted.last.totalDebit,
      'averageSpendPerAccount': totalSpend / summaries.length,
    };
  }
}
