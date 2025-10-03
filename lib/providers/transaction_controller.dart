import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sms_service.dart';
import '../services/transaction_aggregator.dart';
import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';
import '../types/transaction.dart';

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

final transactionAggregatorProvider = Provider<TransactionAggregator>((ref) {
  return TransactionAggregator();
});

final transactionControllerProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final smsService = ref.watch(smsServiceProvider);
  final aggregator = ref.watch(transactionAggregatorProvider);
  return TransactionNotifier(smsService: smsService, aggregator: aggregator);
});

class TransactionState {
  const TransactionState({
    required this.permissionGranted,
    required this.permissionPermanentlyDenied,
    required this.isLoading,
    required this.transactions,
    required this.monthlySummaries,
    required this.accountSummaries,
    required this.overview,
    required this.errorMessage,
  });

  factory TransactionState.initial() => TransactionState(
        permissionGranted: false,
        permissionPermanentlyDenied: false,
        isLoading: false,
        transactions: const [],
        monthlySummaries: const [],
        accountSummaries: const [],
        overview: DashboardOverview(
          totalDebit: 0,
          totalCredit: 0,
          transactionCount: 0,
          topAccounts: const <AccountSummary>[],
          lastUpdated: null,
        ),
        errorMessage: null,
      );

  final bool permissionGranted;
  final bool permissionPermanentlyDenied;
  final bool isLoading;
  final List<Transaction> transactions;
  final List<MonthlySummary> monthlySummaries;
  final List<AccountSummary> accountSummaries;
  final DashboardOverview overview;
  final String? errorMessage;

  TransactionState copyWith({
    bool? permissionGranted,
    bool? permissionPermanentlyDenied,
    bool? isLoading,
    List<Transaction>? transactions,
    List<MonthlySummary>? monthlySummaries,
    List<AccountSummary>? accountSummaries,
    DashboardOverview? overview,
    Object? errorMessage = _sentinel,
  }) {
    return TransactionState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      permissionPermanentlyDenied:
          permissionPermanentlyDenied ?? this.permissionPermanentlyDenied,
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      monthlySummaries: monthlySummaries ?? this.monthlySummaries,
      accountSummaries: accountSummaries ?? this.accountSummaries,
      overview: overview ?? this.overview,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _sentinel = Object();
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier({
    required SmsService smsService,
    required TransactionAggregator aggregator,
  })  : _smsService = smsService,
        _aggregator = aggregator,
        super(TransactionState.initial());

  final SmsService _smsService;
  final TransactionAggregator _aggregator;

  Future<void> initialize() async {
    await _handlePermissionFlow();
  }

  Future<void> refresh() async {
    if (!state.permissionGranted) {
      await _handlePermissionFlow();
      return;
    }
    await _loadTransactions();
  }

  Future<void> requestPermissionAgain() async {
    await _handlePermissionFlow();
  }

  Future<void> openSettings() async {
    await _smsService.openSettings();
  }

  Future<void> _handlePermissionFlow() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _smsService.ensurePermission();
    switch (result) {
      case SmsPermissionResult.granted:
        state = state.copyWith(
          permissionGranted: true,
          permissionPermanentlyDenied: false,
        );
        await _loadTransactions();
        break;
      case SmsPermissionResult.denied:
        state = state.copyWith(
          permissionGranted: false,
          permissionPermanentlyDenied: false,
          isLoading: false,
          errorMessage: 'SMS permission is required to analyse transactions.',
        );
        break;
      case SmsPermissionResult.permanentlyDenied:
        state = state.copyWith(
          permissionGranted: false,
          permissionPermanentlyDenied: true,
          isLoading: false,
          errorMessage:
              'SMS permission has been permanently denied. Please enable it from system settings.',
        );
        break;
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final messages = await _smsService.queryAndParseSms();
      final monthly = _aggregator.buildMonthlySummaries(messages);
      final accounts = _aggregator.buildAccountSummaries(messages);
      final overview = _aggregator.buildDashboardOverview(messages, accounts);

      state = state.copyWith(
        isLoading: false,
        transactions: messages,
        monthlySummaries: monthly,
        accountSummaries: accounts,
        overview: overview,
        errorMessage: null,
      );
    } catch (err, stack) {
      debugPrint('Failed to load SMS messages: $err\n$stack');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load SMS messages. Please try again.',
      );
    }
  }
}
