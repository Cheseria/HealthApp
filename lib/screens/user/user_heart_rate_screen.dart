import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heart_bpm/chart.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  int buttonIndex = 0; // 0 for daily, 1 for weekly
  double dailyAverage = 0;
  double weeklyAverage = 0;

  late PageController _dayPageController;
  late PageController _weekPageController;
  DateTime _currentDay = DateTime.now();
  DateTime _startOfCurrentWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void storeHeartRateData(String userId, int bpm, DateTime timestamp) {
    // Format the date as a string (e.g., "2023-11-04")
    String dateString = DateFormat('yyyy-MM-dd').format(timestamp);

    // Reference to the date-named document
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('heartRateData')
        .doc(dateString);

    // Use a unique sub-field for each BPM entry
    String timeString = DateFormat('HH:mm:ss').format(timestamp);

    // Update the document by adding a new map entry for the timestamp
    docRef.set({
      'heartRates': {
        timeString: bpm,
      },
      'date': dateString,
    }, SetOptions(merge: true)).then((_) {
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

        buildHeartRateInfoForDay(userId, DateTime.now());
      }
    });

    _measurementTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _dayPageController = PageController(initialPage: 7);
    _weekPageController = PageController(initialPage: 3);
  }

  @override
  void dispose() {
    _measurementTimer?.cancel(); // Ensure timer is canceled when disposing
    _dayPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> retrieveDailyHeartRateData(
      String userId, DateTime day) async {
    // Format the date as 'yyyy-MM-dd' to match the document ID
    String dayId = DateFormat('yyyy-MM-dd').format(day);

    // Reference to the specific day's document in Firebase
    DocumentReference dayDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('heartRateData')
        .doc(dayId);

    // Fetch the day's heart rate document
    DocumentSnapshot snapshot = await dayDoc.get();

    if (snapshot.exists && snapshot.data() != null) {
      // Get the data as a map
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Retrieve individual heart rate records inside the 'heartRates' field
      Map<String, dynamic>? heartRates =
          data['heartRates'] as Map<String, dynamic>?;

      if (heartRates != null && heartRates.isNotEmpty) {
        List<int> bpmValues = [];
        List<Map<String, dynamic>> timestampedDataPoints = [];

        // Safely iterate over heartRates to collect data points
        heartRates.forEach((time, record) {
          if (record is int) {
            // Ensure each record is an integer BPM value
            bpmValues.add(record);
            timestampedDataPoints.add({'time': time, 'bpm': record});
          }
        });

        if (bpmValues.isNotEmpty) {
          int minBPM = bpmValues.reduce((a, b) => a < b ? a : b);
          int maxBPM = bpmValues.reduce((a, b) => a > b ? a : b);
          int bpmRange = maxBPM - minBPM;

          return {
            'minBPM': minBPM,
            'maxBPM': maxBPM,
            'range': bpmRange,
            'timestampedDataPoints': timestampedDataPoints,
          };
        }
      }
    }

    // Return default values if no data is found
    return {
      'minBPM': 0,
      'maxBPM': 0,
      'range': 0,
      'timestampedDataPoints': <Map<String, dynamic>>[],
    };
  }

  Future<Map<String, dynamic>> retrieveWeeklyHeartRateData(
      String userId, DateTime startOfWeek) async {
    Map<String, dynamic> heartRateData = {
      'averageBPM': 0,
      'timestampedDataPoints': []
    };

    try {
      CollectionReference heartRateCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('heartRateData');

      String startOfWeekStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
      String endOfWeekStr =
          DateFormat('yyyy-MM-dd').format(startOfWeek.add(Duration(days: 6)));

      QuerySnapshot snapshot = await heartRateCollection
          .where('date', isGreaterThanOrEqualTo: startOfWeekStr)
          .where('date', isLessThanOrEqualTo: endOfWeekStr)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> timestampedDataPoints = [];
        Map<int, List<int>> dailyBPMs = {};

        for (var doc in snapshot.docs) {
          Map<String, dynamic> heartRateRecord =
              doc.data() as Map<String, dynamic>;

          if (heartRateRecord.containsKey('heartRates')) {
            Map<String, dynamic> heartRates = heartRateRecord['heartRates'];

            heartRates.forEach((time, bpm) {
              timestampedDataPoints.add({
                'time': time,
                'bpm': bpm,
              });

              // Calculate day index (0 = Monday, 6 = Sunday)
              DateTime timestamp = DateFormat('HH:mm:ss').parse(time);
              int dayIndex =
                  (timestamp.weekday - 1) % 7; // Convert to 0-based index

              // Add BPM to the corresponding day's list
              if (!dailyBPMs.containsKey(dayIndex)) {
                dailyBPMs[dayIndex] = [];
              }
              dailyBPMs[dayIndex]!.add(bpm);
            });
          }
        }

        // Calculate average BPM for each day of the week
        List<double> averageBPMPerDay = [];
        for (int i = 0; i < 7; i++) {
          if (dailyBPMs.containsKey(i)) {
            List<int> bpmList = dailyBPMs[i]!;
            double averageBPM =
                bpmList.reduce((a, b) => a + b) / bpmList.length;
            averageBPMPerDay.add(averageBPM);
          } else {
            averageBPMPerDay.add(0.0); // No data for this day
          }
        }

        heartRateData['timestampedDataPoints'] = timestampedDataPoints;
        heartRateData['averageBPMPerDay'] = averageBPMPerDay;
      }
    } catch (e) {
      print('Error fetching heart rate data: $e');
    }

    return heartRateData;
  }

// Day View
  Widget dayView() {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height *
            0.6, // Flexible height for scrolling
        child: PageView.builder(
          controller: _dayPageController,
          itemCount: 7, // 7 days
          onPageChanged: (index) {
            setState(() {
              _currentDay = DateTime.now().subtract(Duration(days: 6 - index));
            });
          },
          itemBuilder: (context, index) {
            DateTime day = DateTime.now().subtract(Duration(days: 6 - index));
            return buildHeartRateInfoForDay(userId, day);
          },
        ),
      ),
    );
  }

// Week View
  Widget weekView() {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height *
            0.6, // Flexible height for scrolling
        child: PageView.builder(
          controller: _weekPageController,
          itemCount: 4, // 4 weeks
          onPageChanged: (index) {
            setState(() {
              _startOfCurrentWeek =
                  DateTime.now().subtract(Duration(days: (3 - index) * 7));
            });
          },
          itemBuilder: (context, index) {
            DateTime startOfWeek =
                DateTime.now().subtract(Duration(days: (3 - index) * 7));
            return buildHeartRateInfoForWeek(startOfWeek);
          },
        ),
      ),
    );
  }

  Widget buildHeartRateInfoForDay(String userId, DateTime day) {
    return FutureBuilder<Map<String, dynamic>>(
      future: retrieveDailyHeartRateData(userId, day),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Check for errors in fetching data
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading data. Please try again.",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // Check if snapshot has data, and data is not empty
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No heart rate data available for ${DateFormat('yyyy-MM-dd').format(day)}",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final data = snapshot.data!;

        // Safely retrieve and check timestampedDataPoints to avoid type issues
        final List<Map<String, dynamic>> timestampedDataPoints =
            (data['timestampedDataPoints'] is List<Map<String, dynamic>>)
                ? List<Map<String, dynamic>>.from(data['timestampedDataPoints'])
                : [];

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "${DateFormat('yyyy-MM-dd').format(day)}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            heartRateDataCard(Icons.monitor_heart_outlined, "Minimum BPM",
                "${data['minBPM'] ?? 0}"),
            heartRateDataCard(Icons.monitor_heart_outlined, "Maximum BPM",
                "${data['maxBPM'] ?? 0}"),
            SizedBox(height: 10),
            if (timestampedDataPoints.isNotEmpty) ...[
              Text("Timestamped Data Points:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...timestampedDataPoints.map((point) => Text(
                    "${point['time']}: ${point['bpm']} BPM",
                    style: TextStyle(fontSize: 14),
                  )),
            ] else
              Text("No detailed data points available."),
          ],
        );
      },
    );
  }

  Widget buildHeartRateInfoForWeek(DateTime startOfWeek) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<Map<String, dynamic>>(
      future: retrieveWeeklyHeartRateData(userId, startOfWeek),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            snapshot.data!['timestampedDataPoints'] == null ||
            snapshot.data!['timestampedDataPoints'].isEmpty) {
          return Column(
            children: [
              SizedBox(height: 30),
              Text(
                'Heart Rate Data for Week: ${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(startOfWeek.add(Duration(days: 6)))}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                'No heart rate info for this week',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
            ],
          );
        }

        Map<String, dynamic> heartRateData = snapshot.data!;
        List<double> averageBPMPerDay = heartRateData['averageBPMPerDay'] ?? [];

        return Column(
          children: [
            SizedBox(height: 30),
            Text(
              'Heart Rate Data for Week: ${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(startOfWeek.add(Duration(days: 6)))}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8.0), // Add horizontal padding
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.3, // Limits the height to 30% of screen height
                maxWidth: MediaQuery.of(context).size.width *
                    0.9, // Limits the width to 90% of screen width
              ),
              child: buildHeartRateBarChart(averageBPMPerDay, startOfWeek),
            ),
          ],
        );
      },
    );
  }

  Widget buildHeartRateBarChart(
      List<double> averageBPMPerDay, DateTime startOfWeek) {
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: averageBPMPerDay[i],
              color: Color(0xFF238878),
              width: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 12, color: Colors.black),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                DateTime day = startOfWeek.add(Duration(days: value.toInt()));
                return Text(DateFormat('EEE').format(day));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(
          show: true,
          verticalInterval: 1,
        ),
        maxY: 120,
        minY: 0,
      ),
    );
  }

// Card for displaying heart rate data
  Widget heartRateDataCard(IconData icon, String label, String value) {
    return Card(
      color: Color(0xFFF5F5F5),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF238878),
        title: Text(
          'Heart Rate Monitor',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: Icon(
              Icons.favorite_rounded,
              color: Color(0xFF238878),
            ),
            label: Text(
              "Measure BPM",
              style: TextStyle(color: Color(0xFF238878)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Heart Rate Measurement',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Put your finger between the camera and the flashlight.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[700]),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                // Display Camera for HeartBPMDialog
                                isBPMEnabled
                                    ? HeartBPMDialog(
                                        context: context,
                                        showTextValues: true,
                                        borderRadius: 10,
                                        onRawData: (value) {
                                          setState(() {
                                            if (data.length >= 100)
                                              data.removeAt(0);
                                            data.add(value);
                                          });
                                        },
                                        onBPM: (value) => setState(() {
                                          if (bpmValues.length >= 100)
                                            bpmValues.removeAt(0);
                                          bpmValues.add(SensorValue(
                                              value: value.toDouble(),
                                              time: DateTime.now()));
                                        }),
                                      )
                                    : SizedBox(),
                                SizedBox(height: 20),
                                // Display Countdown Timer
                                isBPMEnabled
                                    ? Text(
                                        "Time remaining: $countdown seconds",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : SizedBox(),
                                SizedBox(height: 20),
                                // Description and Graph for Raw Data
                                if (isBPMEnabled && data.isNotEmpty) ...[
                                  Text(
                                    'Raw Sensor Data',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    decoration:
                                        BoxDecoration(border: Border.all()),
                                    height: 180,
                                    child: BPMChart(data),
                                  ),
                                ],
                                SizedBox(height: 20),
                                // Description and Graph for BPM Values
                                if (isBPMEnabled && bpmValues.isNotEmpty) ...[
                                  Text(
                                    'BPM (Heart Rate) Values',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    decoration:
                                        BoxDecoration(border: Border.all()),
                                    height: 180,
                                    child: BPMChart(bpmValues),
                                  ),
                                ],
                                SizedBox(height: 20),
                                // Display Average BPM
                                if (!isBPMEnabled && bpm > 0)
                                  Text(
                                    "Average BPM: $bpm bpm",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                SizedBox(height: 20),
                                // Start/Stop Button
                                ElevatedButton.icon(
                                  icon: Icon(
                                    Icons.favorite,
                                    color: Color(0xFF238878),
                                  ),
                                  label: Text(
                                    style: TextStyle(color: Color(0xFF238878)),
                                    isBPMEnabled
                                        ? "Stop measurement"
                                        : "Start measurement",
                                  ),
                                  onPressed: () {
                                    if (isBPMEnabled) {
                                      _stopMeasurement();
                                    } else {
                                      _startMeasurement();
                                    }
                                    setState(() {}); // Update dialog state
                                  },
                                ),
                                SizedBox(height: 10),
                                // Close Button
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Close"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 20),
          // Daily/Weekly Averages
          Center(
            child: Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
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
          Center(
            child: buttonIndex == 0 ? dayView() : weekView(),
          ),
        ],
      ),
    );
  }
}
