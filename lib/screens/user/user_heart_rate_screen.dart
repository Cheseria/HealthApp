import 'package:flutter/material.dart';
import 'package:heart_bpm/chart.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'dart:async';

class UserHeartRateScreen extends StatefulWidget {
  @override
  _UserHeartRateScreenState createState() => _UserHeartRateScreenState();
}

class _UserHeartRateScreenState extends State<UserHeartRateScreen> {
  List<SensorValue> data = [];
  List<SensorValue> bpmValues = [];
  bool isBPMEnabled = false;
  Widget? dialog;
  Timer? _measurementTimer;
  int bpm = 0; // Holds the final BPM result
  int countdown = 60; // Countdown display in seconds

  void _startMeasurement() {
    setState(() {
      isBPMEnabled = true;
      data.clear();
      bpmValues.clear();
      countdown = 60; // Reset countdown to 60 seconds
    });

    // Start the 1-minute timer and update countdown every second
    _measurementTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });
      if (countdown <= 0) {
        _stopMeasurement();
      }
    });
  }

  void _stopMeasurement() {
    setState(() {
      isBPMEnabled = false;
      // Calculate the average BPM from bpmValues after stopping
      if (bpmValues.isNotEmpty) {
        bpm = bpmValues.map((v) => v.value).reduce((a, b) => a + b) ~/
            bpmValues.length;
      }
    });

    // Dispose of the timer
    _measurementTimer?.cancel();
  }

  @override
  void dispose() {
    _measurementTimer?.cancel(); // Ensure timer is canceled when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Heart BPM Demo'),
      ),
      body: Column(
        children: [
          isBPMEnabled
              ? dialog = HeartBPMDialog(
                  context: context,
                  showTextValues: true,
                  borderRadius: 10,
                  onRawData: (value) {
                    setState(() {
                      if (data.length >= 100) data.removeAt(0);
                      data.add(value);
                    });
                  },
                  onBPM: (value) => setState(() {
                    if (bpmValues.length >= 100) bpmValues.removeAt(0);
                    bpmValues.add(SensorValue(
                        value: value.toDouble(), time: DateTime.now()));
                  }),
                )
              : SizedBox(),
          isBPMEnabled && data.isNotEmpty
              ? Container(
                  decoration: BoxDecoration(border: Border.all()),
                  height: 180,
                  child: BPMChart(data),
                )
              : SizedBox(),
          isBPMEnabled && bpmValues.isNotEmpty
              ? Container(
                  decoration: BoxDecoration(border: Border.all()),
                  constraints: BoxConstraints.expand(height: 180),
                  child: BPMChart(bpmValues),
                )
              : SizedBox(),
          SizedBox(height: 20),
          // Countdown timer display
          isBPMEnabled
              ? Text("Time remaining: $countdown seconds",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              : SizedBox(),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.favorite_rounded),
              label: Text(isBPMEnabled ? "Stop measurement" : "Measure BPM"),
              onPressed: () {
                if (isBPMEnabled) {
                  _stopMeasurement();
                } else {
                  _startMeasurement();
                }
              },
            ),
          ),
          SizedBox(height: 20),
          // Display the average BPM after measurement ends
          !isBPMEnabled && bpm > 0
              ? Text("Average BPM: $bpm bpm", style: TextStyle(fontSize: 20))
              : SizedBox(),
        ],
      ),
    );
  }
}
