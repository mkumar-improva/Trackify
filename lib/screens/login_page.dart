import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trackify/screens/home.dart';
import 'package:trackify/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseServices firebaseServices = FirebaseServices();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final userCredential = await firebaseServices.loginUsingGoogle();
            if(userCredential != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MyApp() ));
            }
          },
          child: Text('Sign-In with Google'),
        ),
      ),
    );
  }

  
}
