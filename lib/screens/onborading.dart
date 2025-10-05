// lib/onboarding.dart
import 'package:flutter/material.dart';
import 'package:flutter_overboard/flutter_overboard.dart';
import 'package:trackify/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onFinished, required this.onSkip});
  final VoidCallback onFinished;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final pages = <PageModel>[
      PageModel(
        color: const Color(0xFFF8F8F8),
        imageAssetPath: 'assets/images/3d/credit_card.png',
        title: 'Track Automatically',
        body: 'We securely read your transaction SMS and organize all your accounts in one place — no manual work needed.',
        doAnimateImage: true,
        bodyColor: AppTheme.neonLime,
        titleColor: AppTheme.neonLime,
      ),
      PageModel(
        color: const Color(0xFFF8F8F8),
        imageAssetPath: 'assets/images/3d/analytics.png',
        title: 'View Smart Analytics',
        body: 'See where your money goes. Get clear visual insights grouped by each bank account and category.',
        doAnimateImage: true,
        bodyColor: AppTheme.neonLime,
        titleColor: AppTheme.neonLime,
      ),
      PageModel(
        color: const Color(0xFFF8F8F8),
        imageAssetPath: 'assets/images/3d/wallet_with_cash.png',
        title: 'AI Insights for You',
        body: 'Get personalized spending feedback, saving tips, and monthly summaries powered by AI.',
        doAnimateImage: true,
        bodyColor: AppTheme.neonLime,
        titleColor: AppTheme.neonLime,
      ),
      // (Optional) a fully custom child slide
      PageModel.withChild(
        color: const Color(0xFFF8F8F8),
        doAnimateChild: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 120, color: AppTheme.neonLime),
              SizedBox(height: 16),
              Text('Ready to go!', style: TextStyle(fontSize: 22, color: AppTheme.neonLime)),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      body: OverBoard(
        pages: pages,
        showBullets: true,
        allowScroll: true,
        inactiveBulletColor: AppTheme.neonLime,
        activeBulletColor: AppTheme.linkPurple,
        skipCallback: onSkip,
        finishCallback: onFinished,
        buttonColor: AppTheme.neonLime,
      ),
    );
  }
}
