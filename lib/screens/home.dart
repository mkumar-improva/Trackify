import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    final bool showOnboarding = state.permissionGranted && state.needsOnboarding;
    final bool showActions = state.permissionGranted && !showOnboarding;
    final theme = Theme.of(context);

    void switchToTimeline() {
      setState(() {
        _currentIndex = 1;
      });
    }

    final tabs = [
      RefreshIndicator(
        onRefresh: notifier.refresh,
        child: DashboardScreen(
          overview: selection.overview,
          accounts: selection.accounts,
          onViewTimeline: showActions ? switchToTimeline : null,
          onManageAccounts: showActions ? _openAccountManager : null,
          onRefresh: notifier.refresh,
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
    final DateTime? lastUpdated = selection.overview.lastUpdated;
    final String greeting = _greeting();

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

    final List<Widget> layeredContent = [
      Positioned.fill(child: content),
    ];

    if (state.errorMessage != null && state.permissionGranted) {
      layeredContent.add(
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: _ErrorBanner(
            message: state.errorMessage!,
            onRetry: notifier.refresh,
          ),
        ),
      );
    }

    if (state.permissionGranted && state.isLoading) {
      layeredContent.add(
        const Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x2FFFFFFF)),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F3DDE),
              Color(0xFF1A73E8),
              Color(0xFFEFF4FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _HomeHeader(
                greeting: greeting,
                showAccountSelector: showActions,
                accountOptions: accountOptions,
                selectedValue: selectedValue,
                onAccountSelected: showActions
                    ? (value) {
                        notifier.selectAccount(
                          value == _allAccountsKey ? null : value,
                        );
                      }
                    : null,
                onManageAccounts: showActions ? _openAccountManager : null,
                onRefresh: showActions ? notifier.refresh : null,
                lastUpdated: lastUpdated,
                isSyncing: state.isLoading,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                      ),
                      child: Stack(children: layeredContent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: state.permissionGranted && !showOnboarding
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: NavigationBar(
                    height: 68,
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.96),
                    indicatorColor:
                        theme.colorScheme.primaryContainer.withOpacity(0.7),
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (idx) {
                      setState(() {
                        _currentIndex = idx;
                      });
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.article_outlined),
                        selectedIcon: Icon(Icons.article),
                        label: 'Timeline',
                      ),
                    ],
                  ),
                ),
              ),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.showAccountSelector,
    required this.accountOptions,
    required this.selectedValue,
    required this.onAccountSelected,
    required this.onManageAccounts,
    required this.onRefresh,
    required this.lastUpdated,
    required this.isSyncing,
  });

  final String greeting;
  final bool showAccountSelector;
  final List<_AccountOption> accountOptions;
  final String selectedValue;
  final ValueChanged<String>? onAccountSelected;
  final VoidCallback? onManageAccounts;
  final VoidCallback? onRefresh;
  final DateTime? lastUpdated;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    String lastUpdatedLabel() {
      if (isSyncing) {
        return 'Syncing your activity…';
      }
      if (lastUpdated == null) {
        return 'Waiting for new insights';
      }
      final formatter = DateFormat('MMM d · h:mm a');
      return 'Updated ${formatter.format(lastUpdated!)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Trackify Pay',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onManageAccounts != null)
                _HeaderIconButton(
                  icon: Icons.account_balance_wallet_outlined,
                  tooltip: 'Manage accounts',
                  onPressed: onManageAccounts,
                ),
              if (onRefresh != null)
                _HeaderIconButton(
                  icon: Icons.sync,
                  tooltip: 'Refresh transactions',
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (showAccountSelector) ...[
            Text(
              'Pay with',
              style: textTheme.labelLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withOpacity(0.14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.expand_more,
                    color: Colors.white,
                  ),
                  dropdownColor: theme.colorScheme.surface,
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  items: accountOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: onAccountSelected,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Set up Trackify Pay to start seeing your insights.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lastUpdatedLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              if (isSyncing)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.14),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
