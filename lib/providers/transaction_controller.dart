import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_config_service.dart';
import '../services/sms_service.dart';
import '../services/transaction_aggregator.dart';
import '../types/account_config.dart';
import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';
import '../types/transaction.dart';

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

final transactionAggregatorProvider = Provider<TransactionAggregator>((ref) {
  return TransactionAggregator();
});

final accountConfigServiceProvider = Provider<AccountConfigService>((ref) {
  return AccountConfigService();
});

final transactionControllerProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final smsService = ref.watch(smsServiceProvider);
  final aggregator = ref.watch(transactionAggregatorProvider);
  final accountConfigService = ref.watch(accountConfigServiceProvider);
  return TransactionNotifier(
    smsService: smsService,
    aggregator: aggregator,
    accountConfigService: accountConfigService,
  );
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
    required this.needsOnboarding,
    required this.availableSenders,
    required this.accountConfigs,
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
        needsOnboarding: false,
        availableSenders: const [],
        accountConfigs: const [],
      );

  final bool permissionGranted;
  final bool permissionPermanentlyDenied;
  final bool isLoading;
  final List<Transaction> transactions;
  final List<MonthlySummary> monthlySummaries;
  final List<AccountSummary> accountSummaries;
  final DashboardOverview overview;
  final String? errorMessage;
  final bool needsOnboarding;
  final List<String> availableSenders;
  final List<AccountConfig> accountConfigs;

  TransactionState copyWith({
    bool? permissionGranted,
    bool? permissionPermanentlyDenied,
    bool? isLoading,
    List<Transaction>? transactions,
    List<MonthlySummary>? monthlySummaries,
    List<AccountSummary>? accountSummaries,
    DashboardOverview? overview,
    Object? errorMessage = _sentinel,
    bool? needsOnboarding,
    List<String>? availableSenders,
    List<AccountConfig>? accountConfigs,
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
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      availableSenders: availableSenders ?? this.availableSenders,
      accountConfigs: accountConfigs ?? this.accountConfigs,
    );
  }

  static const Object _sentinel = Object();
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier({
    required SmsService smsService,
    required TransactionAggregator aggregator,
    required AccountConfigService accountConfigService,
  })  : _smsService = smsService,
        _aggregator = aggregator,
        _configService = accountConfigService,
        super(TransactionState.initial());

  final SmsService _smsService;
  final TransactionAggregator _aggregator;
  final AccountConfigService _configService;

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

  Future<void> completeOnboarding(List<AccountConfig> configs) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _configService.saveConfigs(configs);
      final monthly = _aggregator.buildMonthlySummaries(
        state.transactions,
        accountConfigs: configs,
      );
      final accounts = _aggregator.buildAccountSummaries(
        state.transactions,
        accountConfigs: configs,
      );
      final overview =
          _aggregator.buildDashboardOverview(state.transactions, accounts);

      state = state.copyWith(
        isLoading: false,
        needsOnboarding: false,
        accountConfigs: configs,
        monthlySummaries: monthly,
        accountSummaries: accounts,
        overview: overview,
        errorMessage: null,
      );
    } catch (err, stack) {
      debugPrint('Failed to save account configs: $err\n$stack');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Failed to save account configuration. Please try again.',
      );
    }
  }

  void skipOnboarding() {
    state = state.copyWith(needsOnboarding: false);
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
      final configs = await _configService.loadConfigs();
      final senders = messages
          .map((m) => m.sender)
          .where((sender) => sender.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final monthly =
          _aggregator.buildMonthlySummaries(messages, accountConfigs: configs);
      final accounts =
          _aggregator.buildAccountSummaries(messages, accountConfigs: configs);
      final overview = _aggregator.buildDashboardOverview(messages, accounts);

      state = state.copyWith(
        isLoading: false,
        transactions: messages,
        monthlySummaries: monthly,
        accountSummaries: accounts,
        overview: overview,
        errorMessage: null,
        accountConfigs: configs,
        availableSenders: senders,
        needsOnboarding: senders.isNotEmpty && configs.isEmpty,
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
