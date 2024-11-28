import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background/flutter_background.dart';
import 'firebase_options.dart';
import 'package:healthapp/screens/auth_screen.dart';
import 'package:healthapp/services/background_tasks.dart'; // Import your background task file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AndroidAlarmManager.initialize();

  print("Initializing background tasks...");
  await initializeBackgroundTasks();

  runApp(const MyApp());

  // Schedule the background task every 15 minutes
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 5),
    1, // Unique ID for the task
    BackgroundTasks.syncStepCountToFirebase,
    wakeup: true, // Ensure it wakes up the device if necessary
    exact: true, // Use exact timing for the task
  );

  AndroidAlarmManager.periodic(
    const Duration(days: 1),
    0, // Unique ID for the alarm
    BackgroundTasks.resetBaseStepCount,
    startAt: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 0, 0, 0)
        .add(const Duration(days: 1)), // Start at midnight the next day
    exact: true,
    wakeup: true,
  );
}

/// Initialize background tasks and request necessary permissions
Future<void> initializeBackgroundTasks() async {
  // Request necessary permissions
  bool hasPermissions = await requestPermissions();
  if (!hasPermissions) {
    print("Necessary permissions not granted. Background tasks may not work.");
    return;
  }

  // Enable background execution if needed
  bool isBackgroundEnabled =
      await FlutterBackground.isBackgroundExecutionEnabled;
  if (!isBackgroundEnabled) {
    bool backgroundEnabled = await FlutterBackground.initialize();
    if (backgroundEnabled) {
      await FlutterBackground.enableBackgroundExecution();
      print("Background execution enabled.");
    } else {
      print("Failed to enable background execution.");
    }
  } else {
    print("Background execution already enabled.");
  }

  // Initialize pedometer stream
  print("Calling initializePedometerStream...");
  BackgroundTasks.initializePedometerStream();
}

/// Request necessary permissions for background execution
Future<bool> requestPermissions() async {
  // Request activity recognition permission
  final activityPermission = await Permission.activityRecognition.request();
  if (!activityPermission.isGranted) {
    print("Activity recognition permission denied.");
    return false;
  }

  // Request background execution permission (if required for FlutterBackground)
  final backgroundPermission = await FlutterBackground.hasPermissions;
  if (!backgroundPermission) {
    print("Background execution permission not granted.");
    return false;
  }

  print("All necessary permissions granted.");
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}
