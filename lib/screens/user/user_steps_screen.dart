import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class UserStepsScreen extends StatefulWidget {
  @override
  _UserStepsScreenState createState() => _UserStepsScreenState();
}

class _UserStepsScreenState extends State<UserStepsScreen> {
  int stepCount = 0;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (_isStepDetected(event)) {
        setState(() {
          stepCount++;
        });
      }
    });
  }

  bool _isStepDetected(AccelerometerEvent event) {
    final double threshold = 15.0; // Adjust the threshold as necessary
    final double totalAcceleration =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    return totalAcceleration > threshold;
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
