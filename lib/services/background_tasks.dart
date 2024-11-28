import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; // Required for WidgetsFlutterBinding.ensureInitialized()
import '../firebase_options.dart'; // Import your Firebase options

class BackgroundTasks {
  static StreamSubscription<StepCount>? _stepCountSubscription;

  static void initializePedometerStream() {
    if (_stepCountSubscription == null || _stepCountSubscription!.isPaused) {
      print("Initializing pedometer stream...");
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          print("Step count event received: ${event.steps}");

          // Store the latest total steps in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('totalSteps', event.steps);

          print("Updated total steps in SharedPreferences: ${event.steps}");
        },
        onError: (error) {
          print("Error in pedometer stream: $error");
        },
        cancelOnError: false, // Keep the stream active
      );
      print("Pedometer stream initialized.");
    } else {
      print("Pedometer stream already active.");
    }
  }

  /// Gets the updated step count from the pedometer stream
  static Future<int> getUpdatedStepCountFromPedometer() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int baseStepCount = prefs.getInt('baseStepCount') ?? 0;

      // Use a completer to get the step count from the pedometer stream
      Completer<int> completer = Completer<int>();

      // Set a timeout for the completer
      Future.delayed(Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError("Pedometer stream timeout");
        }
      });

      _stepCountSubscription =
          Pedometer.stepCountStream.listen((StepCount event) {
        int currentSteps = event.steps - baseStepCount;
        if (!completer.isCompleted) {
          completer.complete(currentSteps);
        }
      }, onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      return completer.future;
    } catch (e) {
      print("Error getting updated step count: $e");
      return 0;
    }
  }

  static Future<void> resetBaseStepCount() async {
    print("Resetting base step count...");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Fetch the latest total steps from SharedPreferences
      int latestTotalSteps = prefs.getInt('totalSteps') ?? 0;

      // Set the latest total steps as the new base step count
      await prefs.setInt('baseStepCount', latestTotalSteps);

      print("Base step count reset to: $latestTotalSteps");
    } catch (e) {
      print("Error resetting base step count: $e");
    }
  }

  /// Syncs the updated step count to Firebase
  static Future<void> syncStepCountToFirebase() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Fetch updated step count
      int updatedSteps = await getUpdatedStepCountFromPedometer();
      print("$updatedSteps");
      int lastSyncedSteps = prefs.getInt('lastSyncedSteps') ?? 0;

      // Store the updated steps locally for the UI
      await _storeStepCount(updatedSteps);
      print("Stored step count locally: $updatedSteps");

      // Sync only if steps have changed
      if (updatedSteps != lastSyncedSteps) {
        String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String currentHour = DateFormat('HH').format(DateTime.now());
        String hourlyInterval =
            "${currentHour}:00-${(int.parse(currentHour) + 1).toString().padLeft(2, '0')}:00";

        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          print("User not logged in. Skipping Firebase sync.");
          return;
        }

        DocumentReference stepCountRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('stepCount')
            .doc(currentDate)
            .collection('hourly')
            .doc(hourlyInterval);

        await stepCountRef.set({
          'steps': updatedSteps,
          'timestamp': Timestamp.now(),
        }, SetOptions(merge: true));

        await prefs.setInt(
            'lastSyncedSteps', updatedSteps); // Cache last synced steps
        print("Updated steps: $updatedSteps stored to Firebase.");
      } else {
        print("No changes in step count. Skipping Firebase sync.");
      }
    } catch (e) {
      print("Error syncing updated steps: $e");
    }
  }

  /// Stores the step count locally in SharedPreferences
  static Future<void> _storeStepCount(int steps) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stepCount', steps);
      print("Stored step count locally: $steps");
    } catch (e) {
      print("Error storing step count locally: $e");
    }
  }

  /// Disposes the pedometer stream subscription
  static Future<void> disposePedometerStream() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    print("Pedometer stream subscription canceled.");
  }
}
