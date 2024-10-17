import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthapp/screens/welcome_screen.dart';
import 'package:healthapp/widgets/doctor_navbar_roots.dart';
import 'package:healthapp/widgets/user_navbar_roots.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If user is logged in
          if (snapshot.hasData) {
            String userId = snapshot.data!.uid;

            // Fetch user data from Firestore
            return FutureBuilder<Map<String, dynamic>?>(
              future: fetchUserData(userId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return Center(child: Text("Error fetching user data"));
                }

                // Get the user's role and other data
                Map<String, dynamic> userData = userSnapshot.data!;
                String userRole = userData['role'];

                // Navigate to the appropriate navbar
                if (userRole == 'doctor') {
                  return DoctorNavbarRoots(userData: userData);
                } else if (userRole == 'user') {
                  return UserNavbarRoots(userData: userData);
                } else {
                  return Center(child: Text("Invalid user role"));
                }
              },
            );
          } else {
            return WelcomeScreen();
          }
        },
      ),
    );
  }
}
