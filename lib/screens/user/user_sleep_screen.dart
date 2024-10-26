import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSleepScreen extends StatefulWidget {
  @override
  _UserSleepScreenState createState() => _UserSleepScreenState();
}

class _UserSleepScreenState extends State<UserSleepScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _dayPageController;
  late PageController _weekPageController;

  DateTime _currentDay = DateTime.now();
  DateTime _startOfCurrentWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Only Day and Week
    _dayPageController = PageController(initialPage: 29); // Start from today
    _weekPageController =
        PageController(initialPage: 3); // Start from the most recent week
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dayPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  void storeSleepData(
      String userId, DateTime day, DateTime sleepTime, DateTime wakeTime) {
    // Calculate the duration in hours
    Duration sleepDuration = wakeTime.difference(sleepTime);
    double durationInHours = sleepDuration.inMinutes / 60;

    // Store sleep data in Firestore under the user's collection
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users') // Collection for users
        .doc(userId) // User document
        .collection('sleepData') // Sub-collection for sleep data
        .doc(DateFormat('yyyy-MM-dd')
            .format(day)); // Document ID based on the date

    docRef.set({
      'sleepTime': sleepTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'duration': durationInHours,
      'date': DateFormat('yyyy-MM-dd').format(day),
    }).then((_) {
      setState(() {}); // Call setState after saving to refresh the UI
    }).catchError((error) {
      print("Failed to save data: $error");
    });
  }

  void _showSleepInputDialog(String userId, DateTime day) {
    DateTime selectedSleepTime =
        day.subtract(Duration(days: 1)); // Previous day night
    DateTime selectedWakeTime = day; // Morning of the same day

    DateTime selectedSleepDate = day.subtract(Duration(days: 1));
    DateTime selectedWakeDate = day;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Input Sleep Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sleep Date Selection
                  Text('Sleep Time:'),
                  DropdownButton<DateTime>(
                    value: selectedSleepDate,
                    items: [
                      DropdownMenuItem(
                        child: Text(DateFormat('yyyy-MM-dd')
                            .format(day.subtract(Duration(days: 1)))),
                        value: day.subtract(Duration(days: 1)),
                      ),
                      DropdownMenuItem(
                        child: Text(DateFormat('yyyy-MM-dd').format(day)),
                        value: day,
                      ),
                    ],
                    onChanged: (DateTime? newDate) {
                      setState(() {
                        selectedSleepDate = newDate!;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedSleepTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedSleepTime = DateTime(
                            selectedSleepDate.year,
                            selectedSleepDate.month,
                            selectedSleepDate.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Text(DateFormat('HH:mm').format(selectedSleepTime)),
                  ),
                  SizedBox(height: 20),

                  // Wake Date Selection
                  Text('Wake Time:'),
                  DropdownButton<DateTime>(
                    value: selectedWakeDate,
                    items: [
                      DropdownMenuItem(
                        child: Text(DateFormat('yyyy-MM-dd')
                            .format(day.subtract(Duration(days: 1)))),
                        value: day.subtract(Duration(days: 1)),
                      ),
                      DropdownMenuItem(
                        child: Text(DateFormat('yyyy-MM-dd').format(day)),
                        value: day,
                      ),
                    ],
                    onChanged: (DateTime? newDate) {
                      setState(() {
                        selectedWakeDate = newDate!;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedWakeTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedWakeTime = DateTime(
                            selectedWakeDate.year,
                            selectedWakeDate.month,
                            selectedWakeDate.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Text(DateFormat('HH:mm').format(selectedWakeTime)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Store sleep data when the user presses Save
                    storeSleepData(
                        userId, day, selectedSleepTime, selectedWakeTime);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Close the dialog without saving
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String analyzeSleepDuration(double durationInHours) {
    if (durationInHours >= 7) {
      return "Great! You had sufficient sleep last night!";
    } else if (durationInHours >= 5 && durationInHours < 7) {
      return "You had a decent sleep, but consider resting a bit more.";
    } else {
      return "You didn't get enough sleep. Try to rest more.";
    }
  }

// Function to fetch sleep data for the week
  Future<List<Map<String, dynamic>>> fetchWeeklySleepData(
      String userId, DateTime startOfWeek) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users') // Collection for users
        .doc(userId) // User document
        .collection('sleepData') // Sub-collection for sleep data
        .where('date',
            isGreaterThanOrEqualTo:
                DateFormat('yyyy-MM-dd').format(startOfWeek))
        .where('date',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd')
                .format(startOfWeek.add(Duration(days: 6))))
        .get();

    List<Map<String, dynamic>> sleepData = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime sleepTime = DateTime.parse(data['sleepTime']);
      DateTime wakeTime = DateTime.parse(data['wakeTime']);

      sleepData.add({
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
      });
    }

    return sleepData;
  }

  DateTime calculateModeSleepWakeTimes(
      List<Map<String, dynamic>> sleepData, bool isSleepTime) {
    if (sleepData.isEmpty) {
      return DateTime.now(); // Return current time if no data is available
    }

    Map<String, int> frequencyMap = {}; // To store frequency of times

    for (var data in sleepData) {
      DateTime time;

      // Use appropriate field based on isSleepTime flag
      if (isSleepTime) {
        time = data['sleepTime'] is String
            ? DateTime.parse(data['sleepTime']) // Parse string to DateTime
            : data['sleepTime'];
      } else {
        time = data['wakeTime'] is String
            ? DateTime.parse(data['wakeTime']) // Parse string to DateTime
            : data['wakeTime'];
      }

      // Format time to a string without seconds for accurate frequency counting
      String timeKey = DateFormat('hh:mm a').format(time);

      // Increment the count for this time in the frequency map
      frequencyMap[timeKey] = (frequencyMap[timeKey] ?? 0) + 1;
    }

    // Determine the mode from the frequency map
    String modeTimeKey = '';
    int maxFrequency = 0;

    frequencyMap.forEach((key, value) {
      if (value > maxFrequency) {
        maxFrequency = value; // Update max frequency
        modeTimeKey = key; // Update mode time key
      } else if (value == maxFrequency) {
        // If we encounter another time with the same max frequency, choose the earlier time
        DateTime currentTime = DateFormat('hh:mm a').parse(key);
        DateTime modeTime = DateFormat('hh:mm a').parse(modeTimeKey);
        if (currentTime.isBefore(modeTime)) {
          modeTimeKey = key; // Update mode time if current time is earlier
        }
      }
    });

    // Return the mode time as a DateTime object based on the mode key
    if (modeTimeKey.isNotEmpty) {
      return DateFormat('hh:mm a').parse(modeTimeKey);
    }

    return DateTime.now(); // Fallback if mode not found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Last Night's Sleep"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Day'),
            Tab(text: 'Week'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          dayView(), // Day view
          weekView(), // Week view
        ],
      ),
    );
  }

  // Day view with swiping for 30 days
  Widget dayView() {
    return PageView.builder(
      controller: _dayPageController,
      itemCount: 30, // Limit to the past 30 days
      onPageChanged: (index) {
        setState(() {
          _currentDay = DateTime.now().subtract(Duration(days: 29 - index));
        });
      },
      itemBuilder: (context, index) {
        DateTime day = DateTime.now().subtract(Duration(days: 29 - index));
        return buildSleepInfoForDay(userId, day);
      },
    );
  }

  // Week view with swiping for 4 weeks
  Widget weekView() {
    return PageView.builder(
      controller: _weekPageController,
      itemCount: 4, // Limit to the past 4 weeks
      onPageChanged: (index) {
        setState(() {
          _startOfCurrentWeek =
              DateTime.now().subtract(Duration(days: (3 - index) * 7));
        });
      },
      itemBuilder: (context, index) {
        DateTime startOfWeek =
            DateTime.now().subtract(Duration(days: (3 - index) * 7));
        return buildSleepInfoForWeek(startOfWeek);
      },
    );
  }

  Widget buildSleepInfoForDay(String userId, DateTime day) {
    String formattedDay = DateFormat('MMM dd, yyyy').format(day);
    String formattedFirestoreDay =
        DateFormat('yyyy-MM-dd').format(day); // Firestore document ID format

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users') // Collection for users
          .doc(userId) // User document
          .collection('sleepData') // Sub-collection for sleep data
          .doc(formattedFirestoreDay)
          .get(), // Fetch sleep data for the specific day
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator()); // Show loading indicator while fetching data
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // No data available for this day
          return Column(
            children: [
              SizedBox(height: 30),
              Text(
                'Sleep Data for $formattedDay',
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
                'No sleep info for this day',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _showSleepInputDialog(
                      userId, day); // Show the input dialog to input sleep data
                },
              ),
            ],
          );
        } else {
          // Data is available, display it
          var sleepData = snapshot.data!.data() as Map<String, dynamic>?;

          double duration = (sleepData?['duration'] ?? 0).toDouble();

          int hours = duration.floor();
          int minutes = ((duration - hours) * 60).round();

          String sleepAnalysis = analyzeSleepDuration(duration);

          // Ensure sleepTime and wakeTime are DateTime objects
          DateTime sleepDateTime = DateTime.parse(
              sleepData?['sleepTime'] ?? DateTime.now().toIso8601String());
          DateTime wakeDateTime = DateTime.parse(
              sleepData?['wakeTime'] ?? DateTime.now().toIso8601String());

          // Format the time for display
          String formattedSleepTime =
              DateFormat('hh:mm a').format(sleepDateTime); // e.g., 10:00 PM
          String formattedWakeTime =
              DateFormat('hh:mm a').format(wakeDateTime); // e.g., 07:00 AM

          return Column(
            children: [
              SizedBox(height: 30),
              Text(
                'Sleep Data for $formattedDay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Icon(
                Icons.nights_stay,
                size: 50,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Text(
                'Duration: ${hours.toString().padLeft(2, '0')} h ${minutes.toString().padLeft(2, '0')} m',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 30),

              // Use sleepDataCard to display different pieces of information
              sleepDataCard(Icons.nights_stay, 'Sleep Time',
                  '${formattedSleepTime} - ${formattedWakeTime}'),

              sleepDataCard(Icons.insights, 'Sleep Analysis', sleepAnalysis),

              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _showSleepInputDialog(
                      userId, day); // Show the input dialog to edit sleep data
                },
              ),
            ],
          );
        }
      },
    );
  }

  // Build sleep data for a specific week
  Widget buildSleepInfoForWeek(DateTime startOfWeek) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchWeeklySleepData(userId, startOfWeek),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            children: [
              SizedBox(height: 30),
              Text(
                'Sleep Data for Week: ${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(startOfWeek.add(Duration(days: 6)))}',
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
                'No sleep info for this week',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
            ],
          );
        }

        List<Map<String, dynamic>> sleepData = snapshot.data!;
        DateTime modeSleepTime = calculateModeSleepWakeTimes(sleepData, true);
        DateTime modeWakeTime = calculateModeSleepWakeTimes(sleepData, false);

        return Column(
          children: [
            SizedBox(height: 30),
            Text(
              'Sleep Data for Week: ${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(startOfWeek.add(Duration(days: 6)))}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
                padding: EdgeInsets.only(left: 20),
                height: 300,
                width: 400,
                child: buildBarChart(sleepData, startOfWeek)),
            sleepDataCard(Icons.nights_stay, 'Fell asleep at',
                DateFormat('hh:mm a').format(modeSleepTime)),
            sleepDataCard(Icons.sunny, 'Woke up at',
                DateFormat('hh:mm a').format(modeWakeTime)),
          ],
        );
      },
    );
  }

  Widget buildBarChart(
      List<Map<String, dynamic>> sleepData, DateTime startOfWeek) {
    // Initialize a map to hold total sleep durations for each day
    Map<int, double> totalSleepDurationPerDay = {
      0: 0.0, // Monday
      1: 0.0, // Tuesday
      2: 0.0, // Wednesday
      3: 0.0, // Thursday
      4: 0.0, // Friday
      5: 0.0, // Saturday
      6: 0.0, // Sunday
    };

    // Loop through the stored sleep data
    for (var sleepEntry in sleepData) {
      DateTime sleepTime = sleepEntry['sleepTime'] is String
          ? DateTime.parse(sleepEntry['sleepTime'])
          : sleepEntry['sleepTime'];
      DateTime wakeTime = sleepEntry['wakeTime'] is String
          ? DateTime.parse(sleepEntry['wakeTime'])
          : sleepEntry['wakeTime'];

      // Calculate the duration in hours for the bar chart
      Duration sleepDuration = wakeTime.difference(sleepTime);
      double durationInHours = sleepDuration.inHours.toDouble();

      // Calculate the day index (0 = Monday, 6 = Sunday)
      int dayIndex = (sleepTime.weekday - 1) % 7; // Convert to 0-based index

      // Accumulate the duration for that specific day
      totalSleepDurationPerDay[dayIndex] =
          (totalSleepDurationPerDay[dayIndex] ?? 0) + durationInHours;
    }

    // Create bar chart groups based on accumulated durations
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i, // Day index as x-axis value
          barRods: [
            BarChartRodData(
              toY: totalSleepDurationPerDay[i] ?? 0.0, // Use total duration
              color: Color(0xFF238878),
              width: 15,
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
              showTitles: false,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  );
                }
                return SizedBox.shrink(); // Hide half-hour labels
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                DateTime day = startOfWeek.add(Duration(days: value.toInt()));
                return Text(
                  DateFormat('EEE').format(day), // Display day of the week
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(
          show: true,
          verticalInterval: 1, // Set this to 1 for whole number intervals
        ),
        maxY:
            12, // Adjust this according to your maximum expected sleep duration
        minY: 0, // Start Y value at 0
      ),
    );
  }

  Widget sleepDataCard(IconData icon, String title, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(label),
        ),
      ),
    );
  }
}
