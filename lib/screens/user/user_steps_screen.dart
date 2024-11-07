import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class UserStepsScreen extends StatefulWidget {
  @override
  _UserStepsScreenState createState() => _UserStepsScreenState();
}

class _UserStepsScreenState extends State<UserStepsScreen> {
  int stepCount = 0;

  @override
  void initState() {
    super.initState();
    _initializePedometer();
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
