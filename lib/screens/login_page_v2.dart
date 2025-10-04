import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trackify/components/app_logo.dart';
import 'package:trackify/components/auth_divider.dart';
import 'package:trackify/components/labeled_text_field.dart';
import 'package:trackify/components/password_field.dart';
import 'package:trackify/components/primary_button.dart';
import 'package:trackify/components/social_button.dart';
import 'package:trackify/components/text_link.dart';
import 'package:trackify/screens/home.dart';
import 'package:trackify/services/auth_service.dart';
import 'package:trackify/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseServices firebaseServices = FirebaseServices();

  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  _onSignIn() async {
    UserCredential? userCredential = await firebaseServices.loginUsingGoogle();
    if (userCredential != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MyApp()),
      );
    }
  }

  _onSignGoogleIn() async {
    UserCredential? userCredential = await firebaseServices.loginUsingGoogle();
    if (userCredential != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MyApp()),
      );
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      const AppLogo(),
                      const SizedBox(height: 48),
                      Text('Welcome back',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          )),
                      const SizedBox(height: 8),
                      Text('Sign in to your account',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 28),
                      LabeledTextField(
                        label: 'Your email',
                        hintText: 'johndoe@mail.com',
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      PasswordField(
                        label: 'Password',
                        hintText: 'Enter your password',
                        controller: passCtrl,
                      ),
                      const SizedBox(height: 40),
                      PrimaryButton(
                        text: 'Login',
                        onPressed: _onSignIn,
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      const AuthDivider(text: 'Or sign in with'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SocialButton.google(
                              onPressed: _onSignGoogleIn,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
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
