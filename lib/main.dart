import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthapp/screens/user/user_steps_screen.dart';
import 'firebase_options.dart';
import 'package:healthapp/screens/auth_screen.dart';
import 'package:healthapp/services/background_tasks.dart'; // Import your background task file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());

  // Schedule the background task every 15 minutes
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 1),
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
