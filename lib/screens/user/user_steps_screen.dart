import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class UserStepsScreen extends StatefulWidget {
  @override
  _UserStepsScreenState createState() => _UserStepsScreenState();
}

class _UserStepsScreenState extends State<UserStepsScreen> {
  int stepCount = 0;

  @override
  void initState() {
    super.initState();
    _requestPermission(); // Request permission at app startup
  }

  void _requestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _initializePedometer();
    } else if (status.isDenied) {
      print('Permission is denied');
      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission is needed to track steps")),
      );
    } else if (status.isPermanentlyDenied) {
      print('Permission is permanently denied');
      // Show a dialog prompting the user to enable permissions from settings
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Permission permanently denied. Enable it in Settings.")),
      );
    }
  }

  void _initializePedometer() {
    Pedometer.stepCountStream.listen((StepCount event) {
      setState(() {
        stepCount = event.steps;
      });
    }).onError((error) {
      print("Pedometer Error: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Step Counter')),
      body: Center(
        child: Text('Steps: $stepCount', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
