import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase integration
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:intl/intl.dart'; // For date formatting

class UserStepsScreen extends StatefulWidget {
  @override
  _UserStepsScreenState createState() => _UserStepsScreenState();
}

class _UserStepsScreenState extends State<UserStepsScreen>
    with TickerProviderStateMixin {
  int stepCount = 0;
  List<BarChartGroupData> barChartData = [];
  List<Map<String, dynamic>> stepData = [];

  int touchedHour = -1;
  bool isLoading = true;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    print("App initialized");
    _initializeBackgroundTracking();
    _loadStepCount(); // Load stored step count when the app starts
    _setupDailyReset(); // Set up the daily reset at 00:00 AM
    _startFirebaseStepTracking(); // Store step count in Firebase every hour
    _fetchStepData();
  }

  Future<void> _initializeBackgroundTracking() async {
    if (await _requestPermissions()) {
      bool backgroundEnabled = await FlutterBackground.initialize();
      if (backgroundEnabled) {
        await FlutterBackground.enableBackgroundExecution();
        _startStepTracking();
      }
    }
  }

  Future<bool> _requestPermissions() async {
    final activityPermission = await Permission.activityRecognition.request();
    if (activityPermission.isGranted) {
      print("Activity recognition permission granted.");
      return true;
    } else {
      print("Activity recognition permission denied.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity recognition permission denied')),
      );
      return false;
    }
  }

  void _startStepTracking() {
    print("Starting step tracking...");
    Pedometer.stepCountStream.listen((StepCount event) {
      setState(() {
        stepCount = event.steps;
      });
      print("Updated Step Count: $stepCount");

      // Store the step count to SharedPreferences
      _storeStepCountLocally(stepCount);
    }).onError((error) {
      print("Pedometer Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pedometer Error: $error")),
      );
    });
  }

  // Store step count to SharedPreferences
  Future<void> _storeStepCountLocally(int steps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stepCount', steps);
    print("Stored step count to SharedPreferences: $steps");
  }

  // Load stored step count from SharedPreferences
  Future<void> _loadStepCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      stepCount = prefs.getInt('stepCount') ?? 0;
    });
    print("Loaded stored step count: $stepCount");
  }

  // Setup daily reset at 00:00 AM
  void _setupDailyReset() {
    DateTime now = DateTime.now();
    DateTime resetTime = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

    int timeToWait = resetTime.difference(now).inMilliseconds;

    Timer(Duration(milliseconds: timeToWait), () {
      print("Resetting step count for the new day...");
      setState(() {
        stepCount = 0; // Reset the step count at midnight
      });
      _storeStepCountLocally(stepCount); // Optionally store reset step count
      _storeStepCountInFirebase(
          stepCount); // Store reset step count in Firebase
      _setupDailyReset(); // Reinitialize the daily reset for the next day
    });
  }

  // Store the step count to Firebase every hour
  Future<void> _startFirebaseStepTracking() async {
    Timer.periodic(Duration(seconds: 15), (timer) {
      _storeStepCountInFirebase(stepCount);
      print("stored");
    });
  }

  // Store the step count in Firebase under users/{userId}/stepCount/{YYYY-MM-DD}
  Future<void> _storeStepCountInFirebase(int steps) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get the current date in YYYY-MM-DD format
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // Get the current hour in HH:mm format
      String currentHour = DateFormat('HH').format(DateTime.now());

      // Define the hourly interval as "HH:mm-HH:mm"
      String hourlyInterval =
          "${currentHour}:00-${(int.parse(currentHour) + 1).toString().padLeft(2, '0')}:00";

      DocumentReference stepCountRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stepCount')
          .doc(currentDate) // Document named by the current date
          .collection('hourly') // Subcollection for hourly data
          .doc(hourlyInterval); // Document named by the hourly interval

      await stepCountRef.set({
        'steps': steps,
        'timestamp': Timestamp.now(),
      }, SetOptions(merge: true)); // Merge true to update existing data
      print(
          "Stored step count to Firebase: $steps on $currentDate at $hourlyInterval");
    } else {
      print("No user is logged in. Cannot store step count to Firebase.");
    }
  }

  Future<void> _fetchStepData() async {
    setState(() {
      isLoading = true;
      print("barChartData: $barChartData");
    });

    try {
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Fetch hourly data from Firebase
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // Replace with actual user ID
          .collection('stepCount')
          .doc(currentDate)
          .collection('hourly')
          .get();

      // Create a map of hourly steps data
      Map<int, int> hourlySteps = {};
      for (var doc in snapshot.docs) {
        String hourlyInterval = doc.id;
        int steps = doc.data()['steps'] ?? 0;

        // Extract hour (e.g., "10:00-11:00" -> 10)
        int hour = int.parse(hourlyInterval.split(':')[0]);
        hourlySteps[hour] = steps;
      }

      // Populate `stepData` for all 24 hours
      stepData = List.generate(
          24,
          (hour) => {
                'hour': hour,
                'steps': hourlySteps[hour] ??
                    0, // Use 0 if no data exists for that hour
              });

      setState(() {
        barChartData =
            generateHourlyData(stepData); // Generate chart data from stepData
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  List<BarChartGroupData> generateHourlyData(
      List<Map<String, dynamic>> stepData) {
    List<BarChartGroupData> hourlyData = [];
    int previousSteps = 0; // Keep track of previous hour's steps

    for (int hour = 0; hour < 24; hour++) {
      var hourData = stepData.firstWhere(
        (data) => data['hour'] == hour,
        orElse: () => {'steps': 0},
      );

      // Get current hour's accumulated steps
      int currentSteps = hourData['steps'] ?? 0;

      // Calculate the steps for the current hour by subtracting previous hour's steps
      int stepsForCurrentHour = currentSteps - previousSteps;
      stepsForCurrentHour = stepsForCurrentHour < 0
          ? 0
          : stepsForCurrentHour; // Ensure non-negative steps

      // Update previous steps for next iteration
      previousSteps = currentSteps;

      double steps = stepsForCurrentHour.toDouble();

      hourlyData.add(
        BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: steps,
              color: Colors.red,
              width: 15,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    return hourlyData;
  }

  double calculateMaxY(List<Map<String, dynamic>> stepData) {
    int maxSteps = stepData
        .map((data) => data['steps'] ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return maxSteps > 0
        ? (maxSteps * 1.25).ceilToDouble()
        : 1000.0; // Adjusting by 25% for some padding
  }

  @override
  Widget build(BuildContext context) {
    double maxY = calculateMaxY(stepData); // Calculate maxY once
    double screenHeight = MediaQuery.of(context).size.height;
    double chartHeight = screenHeight / 4; // Half the screen height

    return Scaffold(
      appBar: AppBar(
        title: Text('Step Count Bar Chart'),
      ),
      body: Column(children: [
        isLoading
            ? CircularProgressIndicator()
            : Container(
                height: chartHeight,
                padding: const EdgeInsets.only(top: 10.0, right: 10, left: 10),
                child: barChartData.isEmpty
                    ? Center(child: Text('No data available'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barGroups: barChartData,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: maxY / 2,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 40,
                                interval: maxY / 2,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value % 4 == 0) {
                                    return Text(value.toInt().toString());
                                  } else {
                                    return const SizedBox
                                        .shrink(); // Hide label for other hours
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value % 4 == 0) {
                                    return Text(value.toInt().toString());
                                  } else {
                                    return const SizedBox
                                        .shrink(); // Hide label for other hours
                                  }
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                int hour = group.x;
                                double steps = rod.toY;
                                return BarTooltipItem(
                                  'Hour: $hour:00\nSteps: ${steps.toInt()}',
                                  TextStyle(color: Colors.white),
                                );
                              },
                            ),
                            touchCallback:
                                (FlTouchEvent event, barTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    barTouchResponse == null ||
                                    barTouchResponse.spot == null) {
                                  touchedHour = -1;
                                  return;
                                }
                                touchedHour =
                                    barTouchResponse.spot!.touchedBarGroupIndex;
                              });
                            },
                          ),
                        ),
                      ),
              ),
        if (touchedHour != -1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Time: ${touchedHour}:00, Steps: ${barChartData[touchedHour].barRods[0].toY.toInt()}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Text(
          'Steps: $stepCount',
          style: TextStyle(fontSize: 24),
        ),
      ]),
    );
  }
}
