import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/monthly_expense_view.dart';
import '../providers/transaction_controller.dart';
import 'account_onboarding.dart';
import 'dashboard.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(transactionControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionControllerProvider);
    final aggregator = ref.watch(transactionAggregatorProvider);
    final notifier = ref.read(transactionControllerProvider.notifier);

    final theme = Theme.of(context);
    final tabs = [
      RefreshIndicator(
        onRefresh: notifier.refresh,
        child: DashboardScreen(
          overview: state.overview,
          accounts: state.accountSummaries,
        ),
      ),
      RefreshIndicator(
        onRefresh: notifier.refresh,
        child: MonthlyExpenseView(
          monthlySummaries: state.monthlySummaries,
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
        title: const Text('Trackify'),
        actions: [
          if (!showOnboarding)
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
