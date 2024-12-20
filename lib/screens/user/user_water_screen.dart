import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/auth_screen.dart';

class UserWaterScreen extends StatefulWidget {
  @override
  _UserWaterScreenState createState() => _UserWaterScreenState();
}

class _UserWaterScreenState extends State<UserWaterScreen>
    with TickerProviderStateMixin {
  late AnimationController waveController;
  late Animation<double> waveAnimation;
  ValueNotifier<double> waterLevel = ValueNotifier(1.0); // Start at 100%

  double dailyWaterIntake = 3000.0; // ml based on baseline
  bool lowWaterNotified = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Initialize wave animation controller
    waveController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    waveAnimation = Tween<double>(begin: 0.0, end: 2 * 3.141592653589793)
        .animate(CurvedAnimation(parent: waveController, curve: Curves.linear))
      ..addListener(() {
        setState(() {});
      });

    waveController.repeat(); // Continuously animates the wave

    // Fetch initial water level from SharedPreferences
    _fetchInitialWaterLevel();

    // Timer to periodically fetch water level from SharedPreferences
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.reload(); // Ensure fresh data is fetched from disk
        double currentLevel = prefs.getDouble('currentWaterLevel') ?? 1.0;

        print("Fetched water level after reload: $currentLevel");

        if (currentLevel != waterLevel.value) {
          setState(() {
            waterLevel.value = currentLevel;

            // Check if water level falls below 60% for notification
            if (waterLevel.value < 0.6 && !lowWaterNotified) {
              notifyLowWaterLevel();
              lowWaterNotified = true;
            } else if (waterLevel.value >= 0.6) {
              lowWaterNotified = false;
            }
          });
        }
      } catch (e) {
        print("Error during periodic fetch: $e");
      }
    });
  }

  void _fetchInitialWaterLevel() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      double initialLevel = prefs.getDouble('currentWaterLevel') ?? 1.0;
      setState(() {
        waterLevel.value = initialLevel;
      });
      print("Initial water level fetched: $initialLevel");
    } catch (e) {
      print("Error fetching initial water level: $e");
    }
  }

  // Function to trigger a low water level notification
  void notifyLowWaterLevel() {
    // This is where you could integrate platform notifications
    print("Your hydration level is below 60%. Please drink water!");
  }

  // Function to refill water level by 250ml
  void refillCup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double currentLevel = prefs.getDouble('currentWaterLevel') ?? 1.0;
    double refillAmount =
        250.0 / dailyWaterIntake; // Calculate percentage of a cup refill

    currentLevel = (currentLevel + refillAmount).clamp(0.0, 1.0); // Cap at 100%
    await prefs.setDouble('currentWaterLevel', currentLevel);

    setState(() {
      waterLevel.value = currentLevel;
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the periodic timer
    waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xff2B2C56),
      body: Stack(
        children: [
          // Water level display
          ValueListenableBuilder(
            valueListenable: waterLevel,
            builder: (context, value, child) {
              return Stack(
                children: [
                  Center(
                    child: Text('${(value * 100).toStringAsFixed(0)} %',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(.7)),
                        textScaleFactor: 4),
                  ),
                  CustomPaint(
                    painter: WavePainter(
                      waveAnimation.value,
                      waterLevel.value,
                    ),
                    child: SizedBox(
                      height: size.height,
                      width: size.width,
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 20,
            left: 10,
            child: IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AuthScreen()));
              },
              icon: Icon(
                CupertinoIcons.back,
                color: Colors.white,
              ),
            ),
          ),
          // Button overlay to refill water
          Positioned(
            bottom: 42,
            right: 30,
            child: FloatingActionButton(
              onPressed: refillCup,
              child: Icon(Icons.local_drink),
              backgroundColor: Colors.blueAccent,
            ),
          ),
          // Optional overlay box to display hydration data
          Positioned(
            bottom: 30,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Intake: ${(dailyWaterIntake / 1000).toStringAsFixed(1)} L",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Current Level: ${(waterLevel.value * dailyWaterIntake).toStringAsFixed(0)} ml",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double wavePhase;
  final double waterLevel;

  WavePainter(this.wavePhase, this.waterLevel);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Color(0xff3B6ABA).withOpacity(.8)
      ..style = PaintingStyle.fill;

    var path = Path();
    double waveHeight = 20.0;
    double baseHeight = size.height * (1 - waterLevel); // Adjusted water level

    path.moveTo(0, baseHeight);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            waveHeight *
                sin((i / size.width * 2 * 3.141592653589793) + wavePhase),
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
