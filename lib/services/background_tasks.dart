import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthapp/main.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundTasks {
  static StreamSubscription<StepCount>? _stepCountSubscription;

  /// Calculates water loss based on environmental and user factors
  static Future<void> calculateAndUpdateWaterLoss() async {
    try {
      // Fetch the required data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      double dailyWaterIntake =
          prefs.getDouble('dailyWaterIntake') ?? 3000.0; // ml
      double currentWaterLevel = prefs.getDouble('currentWaterLevel') ??
          1.0; // Percentage (1.0 = 100%)

      // Mock environmental and user activity data
      double baseWaterLossPerHour = 125.0; // ml
      double temperatureFactor = 1.05; // Example for 30°C
      double humidityFactor = 1.1; // Example for 85% humidity
      double stepRateFactor = 1.02; // Example for 300 steps in 15 mins
      double heartRateFactor = 1.0; // Default for normal heart rate
      double ageFactor = 1.0; // Neutral factor for age <= 30

      // Adjust water loss for a 15-minute interval
      double adjustedWaterLoss = (baseWaterLossPerHour / 4) *
          temperatureFactor *
          humidityFactor *
          stepRateFactor *
          heartRateFactor *
          ageFactor;

      // Update water level
      currentWaterLevel =
          (currentWaterLevel - adjustedWaterLoss / dailyWaterIntake)
              .clamp(0.0, 1.0);

      // Save the updated water level in SharedPreferences
      await prefs.setDouble('currentWaterLevel', currentWaterLevel);
      print(
          "Updated water level: ${(currentWaterLevel * 100).toStringAsFixed(1)}%");

      // Trigger notification if water level falls below 60%
      if (currentWaterLevel < 0.6) {
        _notifyLowWaterLevel();
        print("Notification sent!");
      }
    } catch (e) {
      print("Error calculating water loss: $e");
    }
  }

  /// Sends a low water level notification
  static Future<void> _notifyLowWaterLevel() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'water_channel', // Channel ID
      'Water Notifications', // Channel name
      channelDescription: 'Notification for low hydration levels',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Hydration Alert',
      'Your hydration level is below 60%. Please drink water!',
      platformChannelSpecifics,
    );
  }

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
