import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/welcome_screen.dart';
import 'package:healthapp/widgets/navbar_roots.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        //user logged in
        if (snapshot.hasData) {
          return NavbarRoots();
        }
        //user not logged in
        else {
          return WelcomeScreen();
        }
      },
    ));
  }
}
