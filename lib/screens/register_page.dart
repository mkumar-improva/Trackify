import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:trackify/components/app_logo.dart';
import 'package:trackify/components/auth_divider.dart';
import 'package:trackify/components/labeled_text_field.dart';
import 'package:trackify/components/password_field.dart';
import 'package:trackify/components/primary_button.dart';
import 'package:trackify/components/social_button.dart';
import 'package:trackify/components/text_link.dart';
import 'package:trackify/screens/home.dart';
import 'package:trackify/screens/login_page_v2.dart';
import 'package:trackify/services/auth_service.dart';
import 'package:trackify/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebase = FirebaseServices();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _agree = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final userCred = await _firebase.signUp(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          msg = 'Invalid email format.';
          break;
        case 'weak-password':
          msg = 'Password is too weak.';
          break;
        case 'operation-not-allowed':
          msg = 'Email/password sign up is disabled.';
          break;
        default:
          msg = 'Error: ${e.message ?? 'Something went wrong'}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required';
    // very light check to avoid heavy regex
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != passCtrl.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 24),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const AppLogo(),
                      const SizedBox(height: 30),
                        Text(
                          'Create your account',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start tracking your expenses with AI insights',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 28),

                        // Email
                        LabeledTextField(
                          label: 'Email',
                          hintText: 'you@example.com',
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 20),

                        // Password
                        PasswordField(
                          label: 'Password',
                          hintText: 'At least 8 characters',
                          controller: passCtrl,
                          validator: _passwordValidator,
                          // If your PasswordField supports a strength meter, you can pass extra props here.
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password
                        PasswordField(
                          label: 'Confirm password',
                          hintText: 'Re-enter your password',
                          controller: confirmCtrl,
                          validator: _confirmValidator,
                        ),

                        const SizedBox(height: 16),

                        // Terms & Privacy
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agree,
                              onChanged: (v) =>
                                  setState(() => _agree = v ?? false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // TODO: open terms link
                                        },
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // TODO: open privacy link
                                        },
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // const SizedBox(height: 4),

                        // Primary button (full width, consistent radius)
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: _loading
                                ? 'Creating account...'
                                : 'Create account',
                            onPressed: _loading ? () {} : _onRegister,
                          ),
                        ),


                        const SizedBox(height: 18),

                        Center(
                          child: TextLink(
                            text: 'Already have an account? Sign in',
                            color: AppTheme.neonLime,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
