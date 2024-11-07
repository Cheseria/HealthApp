import 'package:flutter/material.dart';
import 'package:heart_bpm/chart.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  int dailyAverage = 72; // Placeholder for daily average BPM
  int weeklyAverage = 75; // Placeholder for weekly average BPM
  int buttonIndex = 0; // Index for daily/weekly switcher

  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void storeHeartRateData(String userId, int bpm, DateTime timestamp) {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('heartRateData')
        .doc(timestamp
            .toIso8601String()); // Unique document ID based on timestamp

    docRef.set({
      'bpm': bpm,
      'timestamp': timestamp.toIso8601String(),
    }).then((_) {
      print("Heart rate data saved successfully");
    }).catchError((error) {
      print("Failed to save heart rate data: $error");
    });
  }

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
      if (bpmValues.isNotEmpty) {
        bpm = bpmValues.map((v) => v.value).reduce((a, b) => a + b) ~/
            bpmValues.length;
        storeHeartRateData(userId, bpm, DateTime.now()); // Call here
      }
    });

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
        mainAxisAlignment: MainAxisAlignment.center,
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

          SizedBox(height: 20),
          // Switcher for daily/weekly averages
          Center(
            child: Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Color(0xfff4f6fa),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        buttonIndex = 0;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                      decoration: BoxDecoration(
                        color: buttonIndex == 0
                            ? Color(0xFF238878)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Daily",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: buttonIndex == 0 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        buttonIndex = 1;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                      decoration: BoxDecoration(
                        color: buttonIndex == 1
                            ? Color(0xFF238878)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Weekly",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: buttonIndex == 1 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // Display the selected average
          Center(
            child: Text(
              buttonIndex == 0
                  ? "Daily Average: $dailyAverage BPM"
                  : "Weekly Average: $weeklyAverage BPM",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
