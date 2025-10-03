import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/monthly_expense_view.dart';
import '../providers/transaction_controller.dart';
import '../types/account_summary.dart';
import '../types/dashboard_overview.dart';
import 'account_onboarding.dart';
import 'dashboard.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const String _allAccountsKey = '__all_accounts__';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(transactionControllerProvider.notifier).initialize(),
    );
  }

  Future<void> _openAccountManager() async {
    final notifier = ref.read(transactionControllerProvider.notifier);
    final currentState = ref.read(transactionControllerProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: AccountOnboardingScreen(
              senders: currentState.availableSenders,
              initialConfigs: currentState.accountConfigs,
              onComplete: (configs) async {
                await notifier.completeOnboarding(configs);
                final navigator = Navigator.of(sheetContext);
                if (navigator.mounted) {
                  navigator.pop();
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionControllerProvider);
    final aggregator = ref.watch(transactionAggregatorProvider);
    final notifier = ref.read(transactionControllerProvider.notifier);
    final selection = _SelectionViewData.fromState(state);
    final selectedValue =
        state.selectedAccountId ?? _allAccountsKey;
    final accountOptions = selection.accountOptions;

    final theme = Theme.of(context);
    final tabs = [
      RefreshIndicator(
        onRefresh: notifier.refresh,
        child: DashboardScreen(
          overview: selection.overview,
          accounts: selection.accounts,
        ),
      ),
      RefreshIndicator(
        onRefresh: notifier.refresh,
        child: MonthlyExpenseView(
          monthlySummaries: selection.monthlySummaries,
          aggregator: aggregator,
        ),
      ),
    ];

    Widget buildPermissionPrompt() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Trackify needs access to your SMS inbox to analyse bank alerts.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We only read transaction-related messages to compute your spending analytics.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: notifier.requestPermissionAgain,
                icon: const Icon(Icons.sms),
                label: const Text('Grant SMS permission'),
              ),
              if (state.permissionPermanentlyDenied) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: notifier.openSettings,
                  child: const Text('Open app settings'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget content;
    final showOnboarding = state.permissionGranted && state.needsOnboarding;

    if (!state.permissionGranted) {
      content = buildPermissionPrompt();
    } else if (showOnboarding) {
      content = AccountOnboardingScreen(
        senders: state.availableSenders,
        onComplete: notifier.completeOnboarding,
        onSkip: () => notifier.skipOnboarding(),
        initialConfigs: state.accountConfigs,
      );
    } else if (state.transactions.isEmpty && state.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = IndexedStack(
        index: _currentIndex,
        children: tabs,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: state.permissionGranted && !showOnboarding
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Trackify'),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      value: selectedValue,
                      items: accountOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        notifier.selectAccount(
                          value == _allAccountsKey ? null : value,
                        );
                      },
                    ),
                  ),
                ],
              )
            : const Text('Trackify'),
        actions: [
          if (state.permissionGranted && !showOnboarding)
            IconButton(
              onPressed: _openAccountManager,
              icon: const Icon(Icons.manage_accounts_outlined),
              tooltip: 'Manage accounts',
            ),
          if (state.permissionGranted && !showOnboarding)
            IconButton(
              onPressed: notifier.refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh transactions',
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: content),
          if (state.errorMessage != null && state.permissionGranted)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ErrorBanner(
                message: state.errorMessage!,
                onRetry: notifier.refresh,
              ),
            ),
          if (state.permissionGranted && state.isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x40FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: state.permissionGranted && !showOnboarding
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timeline_outlined),
                  selectedIcon: Icon(Icons.timeline),
                  label: 'Timeline',
                ),
              ],
            )
          : null,
    );
  }
}

class _SelectionViewData {
  _SelectionViewData({
    required this.monthlySummaries,
    required this.accounts,
    required this.overview,
    required this.accountOptions,
  });

  final List<MonthlySummary> monthlySummaries;
  final List<AccountSummary> accounts;
  final DashboardOverview overview;
  final List<_AccountOption> accountOptions;

  factory _SelectionViewData.fromState(TransactionState state) {
    final List<_AccountOption> options = [
      const _AccountOption(
        value: _HomeShellState._allAccountsKey,
        label: 'All accounts',
      ),
    ];

    options.addAll(
      state.accountSummaries
          .map(
            (account) => _AccountOption(
              value: account.accountKey,
              label: account.displayLabel,
            ),
          )
          .toList(),
    );

    if (state.selectedAccountId == null) {
      return _SelectionViewData(
        monthlySummaries: state.monthlySummaries,
        accounts: state.accountSummaries,
        overview: state.overview,
        accountOptions: options,
      );
    }

    AccountSummary? selectedAccount;
    for (final account in state.accountSummaries) {
      if (account.accountKey == state.selectedAccountId) {
        selectedAccount = account;
        break;
      }
    }

    if (selectedAccount == null) {
      return _SelectionViewData(
        monthlySummaries: state.monthlySummaries,
        accounts: state.accountSummaries,
        overview: state.overview,
        accountOptions: options,
      );
    }

    final sortedMonths = selectedAccount.monthsSortedDescending();
    final monthly = sortedMonths
        .map(
          (month) => MonthlySummary(
            monthKey: month.monthKey,
            accounts: [month],
          ),
        )
        .toList();

    final allTransactions = selectedAccount.monthlyBreakdowns
        .expand((m) => m.transactions)
        .toList();
    final lastUpdated = allTransactions.isEmpty
        ? null
        : allTransactions.reduce(
            (a, b) => a.date.isAfter(b.date) ? a : b,
          ).date;

    final overview = DashboardOverview(
      totalDebit: selectedAccount.totalDebit,
      totalCredit: selectedAccount.totalCredit,
      transactionCount: allTransactions.length,
      topAccounts: [selectedAccount],
      lastUpdated: lastUpdated,
    );

    return _SelectionViewData(
      monthlySummaries: monthly,
      accounts: [selectedAccount],
      overview: overview,
      accountOptions: options,
    );
  }
}

class _AccountOption {
  const _AccountOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: theme.colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
