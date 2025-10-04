import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackify/screens/home.dart';
import 'package:trackify/screens/register_page.dart';
import 'package:trackify/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseServices firebaseServices = FirebaseServices();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Login Page',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                controller: emailController,
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                controller: passwordController,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  String password = passwordController.text.trim();
                  try {
                    await firebaseServices.signIn(email, password);
                    // If we get here, sign in was successful
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => MyApp()),
                    );
                  } on FirebaseAuthException catch (e) {
                    // Handle specific Firebase Auth errors
                    String errorMessage = '';
                    switch (e.code) {
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
                        errorMessage = 'Error: ${e.message}';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An error occurred during sign in'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final userCredential = await firebaseServices
                      .loginUsingGoogle();
                  if (userCredential != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyApp()),
                    );
                  }
                },
                child: Text('Sign-In with Google'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to register page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage()),
                  );
                },
                child: Text('Dont have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
