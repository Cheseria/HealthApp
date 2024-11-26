import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // Required for WidgetsFlutterBinding.ensureInitialized()
import '../firebase_options.dart'; // Import your Firebase options

class BackgroundTasks {
  /// Resets the base step count to the current step count
  static Future<void> resetBaseStepCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int currentStepCount = prefs.getInt('stepCount') ?? 0;

      // Reset base step count
      await prefs.setInt('baseStepCount', currentStepCount);
      print("Base step count reset to: $currentStepCount");
    } catch (e) {
      print("Error resetting base step count: $e");
    }
  }

  /// Syncs the step count to Firebase
  static Future<void> syncStepCountToFirebase() async {
    try {
      // Ensure Flutter bindings and Firebase are initialized
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // Access SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int stepCount = prefs.getInt('stepCount') ?? 0;

      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String currentHour = DateFormat('HH').format(DateTime.now());

      // Define the hourly interval as "HH:mm-HH:mm"
      String hourlyInterval =
          "${currentHour}:00-${(int.parse(currentHour) + 1).toString().padLeft(2, '0')}:00";

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("User not logged in. Skipping Firebase sync.");
        return;
      }

      // Reference to Firebase Firestore
      DocumentReference stepCountRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stepCount')
          .doc(currentDate)
          .collection('hourly')
          .doc(hourlyInterval);

      // Store the step count
      await stepCountRef.set({
        'steps': stepCount,
        'timestamp': Timestamp.now(),
      }, SetOptions(merge: true));

      print("Stored daily steps: $stepCount to Firebase.");
    } catch (e) {
      print("Error syncing step count to Firebase: $e");
    }
  }
}
