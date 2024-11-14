import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Variables for hydration calculations
  double weight = 70.0; // User weight in kg
  double dailyWaterIntake = 3000.0; // ml based on baseline
  double baseWaterLossPerHour = 125.0; // ml per hour
  double temperatureFactor = 1.0; // Base = 1.0
  double humidityFactor = 1.0; // Base = 1.0
  double stepRateFactor = 1.0; // Base = 1.0
  double heartRateFactor = 1.0; // Base = 1.0
  bool lowWaterNotified = false;

  @override
  void initState() {
    super.initState();

    // Initialize wave animation controller
    waveController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    waveAnimation = Tween<double>(begin: 0.0, end: 2 * pi)
        .animate(CurvedAnimation(parent: waveController, curve: Curves.linear))
      ..addListener(() {
        setState(() {});
      });

    waveController.repeat(); // Continuously animates the wave

    // Set daily water intake based on weight (formula: 35 ml per kg)
    dailyWaterIntake =
        weight * 35; // Example baseline: 35ml per kg of body weight

    // Timer for reducing water level every 15 minutes (2 seconds for testing)
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (waterLevel.value > 0) {
        setState(() {
          double waterLoss = calculateWaterLoss();
          waterLevel.value =
              (waterLevel.value - waterLoss / dailyWaterIntake).clamp(0.0, 1.0);

          // Check if water level falls below 60% for notification
          if (waterLevel.value < 0.6 && !lowWaterNotified) {
            notifyLowWaterLevel();
            lowWaterNotified = true; // Prevent duplicate notifications
          } else if (waterLevel.value >= 0.6) {
            lowWaterNotified =
                false; // Reset notification flag if level goes back up
          }
        });
      }
    });
  }

  // Function to trigger a low water level notification
  void notifyLowWaterLevel() {
    // This is where you could integrate platform notifications
    print("Your hydration level is below 60%. Please drink water!");
  }

  // Function to refill water level by 250ml
  void refillCup() {
    setState(() {
      double refillAmount =
          250.0 / dailyWaterIntake; // Calculate percentage of a cup refill
      waterLevel.value =
          (waterLevel.value + refillAmount).clamp(0.0, 1.0); // Cap at 100%
    });
  }

  // Function to calculate water loss based on factors
  double calculateWaterLoss() {
    // Adjusted for a 15-minute period from hourly rate
    double adjustedBaseLoss = baseWaterLossPerHour / 4;

    // Calculate temperature factor (e.g., 1.05 per degree above 28°C)
    double temperature = 30.0; // Sample temperature in °C
    temperatureFactor = 1 + max(0, (temperature - 28) * 0.05);

    // Calculate humidity factor (e.g., increase by 1.1 if > 80% humidity)
    double humidity = 85.0; // Sample humidity in %
    humidityFactor = humidity > 80 ? 1.1 : 1.0;

    // Calculate step rate factor (e.g., increase by 1.02 for moderate steps)
    int currentSteps = 300; // Sample step count over 15 minutes
    stepRateFactor = currentSteps > 100 ? 1.02 : 1.0;

    // Calculate heart rate factor (e.g., increase by 1.03 if above 100 bpm)
    int currentHeartRate = 85; // Sample heart rate in bpm
    heartRateFactor = currentHeartRate > 100 ? 1.03 : 1.0;

    // Total water loss considering environmental and activity factors
    return adjustedBaseLoss *
        temperatureFactor *
        humidityFactor *
        stepRateFactor *
        heartRateFactor;
  }

  @override
  void dispose() {
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
                  Text(
                    "Water Loss Rate: ${(calculateWaterLoss() * 4).toStringAsFixed(1)} ml/hr",
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
        baseHeight + waveHeight * sin((i / size.width * 2 * pi) + wavePhase),
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
