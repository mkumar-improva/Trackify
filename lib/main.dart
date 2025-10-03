
import 'package:flutter/material.dart';
import 'package:trackify/screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackify/firebase_options.dart';
import 'package:trackify/screens/login_page.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
  ));
}






