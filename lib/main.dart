import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackify/firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trackify/screens/login_page_v2.dart';
import 'package:trackify/screens/onborading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(TrackifyApp());
}

class TrackifyApp extends StatefulWidget {
  const TrackifyApp({super.key});

  @override
  State<TrackifyApp> createState() => _TrackifyAppState();
}

class _TrackifyAppState extends State<TrackifyApp> {
  Future<bool> _seenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  Future<void> _setSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: FutureBuilder<bool>(
        future: _seenOnboarding(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.data == true) {
            return const LoginPage();
          }
          // Not seen → show onboarding
          return Builder(
            builder: (ctx) => OnboardingScreen(
              onSkip: () async {
                await _setSeen();
                Navigator.pushReplacement(
                  ctx,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              onFinished: () async {
                await _setSeen();
                Navigator.pushReplacement(
                  ctx,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
