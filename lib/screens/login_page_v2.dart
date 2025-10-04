import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackify/components/app_logo.dart';
import 'package:trackify/components/auth_divider.dart';
import 'package:trackify/components/labeled_text_field.dart';
import 'package:trackify/components/password_field.dart';
import 'package:trackify/components/primary_button.dart';
import 'package:trackify/components/social_button.dart';
import 'package:trackify/components/text_link.dart';
import 'package:trackify/screens/home.dart';
import 'package:trackify/screens/register_page.dart';
import 'package:trackify/services/auth_service.dart';
import 'package:trackify/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseServices firebaseServices = FirebaseServices();

  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool _loading = false;

  // Prevent double navigation when FutureBuilder rebuilds
  bool _didRedirect = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<bool> _seeIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> _setIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _onSignIn() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    setState(() => _loading = true);
    try {
      final userCredential = await firebaseServices.signIn(email, password);
      if (userCredential != null && mounted) {
        _setIsLoggedIn();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = 'The provided credential is invalid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'Error: ${e.message ?? 'Something went wrong'}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSignGoogleIn() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      try {
        final userCredential = await firebaseServices.loginUsingGoogle();
        if (userCredential != null && mounted) {
          _setIsLoggedIn();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found, Please register first')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage =
            'An account already exists with the same email address but different sign-in credentials.';
            break;
          case 'invalid-credential':
            errorMessage = 'The provided credential is invalid.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'This operation is not allowed. Please contact support.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format.';
            break;
          default:
            errorMessage = 'Error: ${e.message ?? 'Something went wrong'}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _registerLinkClick() {
    if (_loading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required';
    if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email';
    return null;
  }

  String? _passwordValidator(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _seeIsLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // If error, fall back to login UI
        if (snapshot.hasError) {
          return _buildLoginScaffold(context);
        }

        final isLoggedIn = snapshot.data == true;

        // Already logged in: redirect once
        if (isLoggedIn) {
          _didRedirect = true;

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
              );
            });
          }
          // Render a tiny shell while redirecting
          return const Scaffold(body: SizedBox.shrink());
        }

        // Not logged in: render login UI
        return _buildLoginScaffold(context);
      },
    );
  }

  // Extracted builder for the login UI
  Widget _buildLoginScaffold(BuildContext context) {
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        const AppLogo(),
                        const SizedBox(height: 48),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 28),

                        // Email
                        LabeledTextField(
                          label: 'Your email',
                          hintText: 'johndoe@mail.com',
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 24),

                        // Password
                        PasswordField(
                          label: 'Password',
                          hintText: 'Enter your password',
                          controller: passCtrl,
                          validator: _passwordValidator,
                        ),

                        const SizedBox(height: 40),

                        // Primary action (keep enabled signature compatible with your component)
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: _loading ? 'Signing in...' : 'Login',
                            onPressed: _loading ? () {} : _onSignIn,
                          ),
                        ),

                        const SizedBox(height: 16),
                        const AuthDivider(text: 'Or sign in with'),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: SocialButton.google(
                                onPressed: _loading ? null : _onSignGoogleIn,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        Center(
                          child: TextLink(
                            text: 'Register as new user',
                            color: AppTheme.neonLime,
                            onTap: _registerLinkClick,
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
