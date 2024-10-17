import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthapp/screens/welcome_screen.dart';
import 'package:healthapp/widgets/doctor_navbar_roots.dart';
import 'package:healthapp/widgets/user_navbar_roots.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User logged in
          if (snapshot.hasData) {
            // Get the user ID
            String userId = snapshot.data!.uid;

            // Fetch user role from Firestore
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  return Center(child: Text("Error fetching user role"));
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Center(child: Text("User role not found"));
                }

                // Get the user's role
                String userRole = userSnapshot.data!['role'];

                // Navigate to the appropriate Navbar based on role
                if (userRole == 'doctor') {
                  return DoctorNavbarRoots();
                } else if (userRole == 'patient') {
                  return UserNavbarRoots();
                } else {
                  return Center(child: Text("Invalid user role"));
                }
              },
            );
          }
          // User not logged in
          else {
            return WelcomeScreen();
          }
        },
      ),
    );
  }
}
