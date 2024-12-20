import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/settings_screen.dart';
import 'package:healthapp/screens/user/user_check_symptoms.dart';
import 'package:healthapp/screens/user/user_heart_rate_screen.dart';
import 'package:healthapp/screens/user/user_sleep_screen.dart';
import 'package:healthapp/screens/user/user_steps_screen.dart';
import 'package:healthapp/screens/user/user_water_screen.dart';

class UserHomeScreen extends StatefulWidget {
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController waveController;
  late Animation<double> waveAnimation;
  ValueNotifier<double> waterLevel = ValueNotifier(0.1); // Starts at 50%

  late AnimationController starController; // Animation controller for stars
  late List<Star> stars; // List to hold star positions
  final int numberOfStars = 30; // Number of stars to display

  late AnimationController terrainController;
  late Animation<double> terrainAnimation;
  late AnimationController heartRateController;

  @override
  void initState() {
    super.initState();

    // Initialize wave animation
    waveController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    waveAnimation = Tween<double>(begin: 0.0, end: 2 * 3.1416)
        .animate(CurvedAnimation(parent: waveController, curve: Curves.linear))
      ..addListener(() {
        setState(() {});
      });

    waveController.repeat(); // Continuously animates the wave

    // Initialize star animation
    starController =
        AnimationController(vsync: this, duration: Duration(seconds: 10))
          ..repeat(); // Loop the star movement

    // Generate random stars initially
    stars = List.generate(numberOfStars, (index) {
      double x = Random().nextDouble() * 400; // Width of the canvas
      double y = Random().nextDouble() * 400; // Height of the canvas
      double radius = Random().nextDouble() * 2; // Smaller radius (0.0 to 1.0)
      return Star(x: x, y: y, radius: radius);
    });

    // Terrain animation controller
    terrainController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Loop every 5 seconds
    )..repeat(); // Repeat the animation

    // Terrain animation value
    terrainAnimation =
        Tween<double>(begin: 0.0, end: 100.0).animate(terrainController);

    // New heartRateController for Heart Rate
    heartRateController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Adjust speed if necessary
    )..repeat();
  }

  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 30, right: 30, bottom: 20, top: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Hello',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFF5ECD81),
                      fontSize: 17,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w400,
                      height: 0,
                    ),
                  ),
                  Text(
                    "${user.displayName}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFF238878),
                      fontSize: 40,
                      fontFamily: 'Kameron',
                      fontWeight: FontWeight.bold,
                      height: 0,
                    ),
                  ),
                ]),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(),
                        ));
                  },
                  icon: Icon(Icons.settings),
                  color: Color(0xFF238878),
                  iconSize: 40,
                )
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserCheckSymptoms(),
                      ));
                },
                child: Container(
                  height: 120,
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFC3D3CC),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          "Feeling sick?",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "Tell me your symptoms",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserHeartRateScreen(),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFC3D3CC), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 115,
                          child: AnimatedBuilder(
                            animation:
                                heartRateController, // Heartbeat animation controller
                            builder: (context, child) {
                              return CustomPaint(
                                painter: HeartRateBackgroundPainter(
                                  heartRateController.value *
                                      100, // Pass animation value
                                ),
                                child: Container(),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(
                                    CupertinoIcons.heart_fill,
                                    color: Colors.red,
                                    size: 25,
                                  ),
                                ),
                                SizedBox(height: 30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Heartrate",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Measure Your Heartrate",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserWaterScreen(),
                      ));
                },
                child: Container(
                  width:
                      MediaQuery.of(context).size.width * 0.4, // Adjust width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFC3D3CC), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: WavePainter(
                              waveAnimation.value, waterLevel.value),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        CupertinoIcons.drop,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    Text(
                                      "Water",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Stay Hydrated",
                                  style: TextStyle(
                                    color: Colors
                                        .white, // White text for visibility
                                  ),
                                ),
                                SizedBox(height: 25),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSleepScreen(),
                      ));
                },
                child: Container(
                  width:
                      MediaQuery.of(context).size.width * 0.4, // Adjust width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFC3D3CC), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: StarryNightPainter(starController.value,
                              stars), // Starry night background
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        CupertinoIcons.moon_fill,
                                        color: Colors.yellow,
                                        size: 25,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      "Sleep Tracker",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors
                                            .white, // Make text color white
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Do you get enough sleep?",
                                  style: TextStyle(
                                    color: Colors
                                        .white, // White text for visibility
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserStepsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFC3D3CC), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: StepsBackgroundPainter(terrainAnimation
                              .value), // Custom background painter
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.directions_walk,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Steps",
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "How far have you gone?",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: InkWell(
                onTap: () {},
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFC3D3CC), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          "Tips of The Day",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    waveController.dispose();
    starController.dispose();
    terrainController.dispose();
    heartRateController.dispose();
    super.dispose();
  }
}

// Star class to represent each star's position and size
class Star {
  double x, y, radius;
  Star({required this.x, required this.y, required this.radius});
}

class StarryNightPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarryNightPainter(this.animationValue, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient for night sky
    Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.deepPurple[900]!, Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw the background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final starPaint = Paint()..color = Colors.white;

    for (var star in stars) {
      // Update star positions smoothly across the screen
      star.x -= 0.5; // Move stars leftwards
      if (star.x < -star.radius) {
        star.x = size.width + star.radius; // Reset when out of view
        star.y =
            Random().nextDouble() * size.height; // Reset at a random height
      }

      // Draw stars on the canvas
      canvas.drawCircle(Offset(star.x, star.y), star.radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for the wave animation
class WavePainter extends CustomPainter {
  final double wavePhase;
  final double waterLevel;

  WavePainter(this.wavePhase, this.waterLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    final path = Path();

    final waveHeight = 5.0; // Wave amplitude
    final waveLength = size.width / 2; // Wave length

    path.moveTo(0, size.height * waterLevel);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * waterLevel +
          sin((x / waveLength * 2 * pi) + wavePhase) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StepsBackgroundPainter extends CustomPainter {
  final double animationValue; // Animation value for movement

  StepsBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Grass (Green top layer)
    final Paint grassPaint = Paint()..color = Color(0xFF00AA00); // Green color
    final Rect grassRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.4);
    canvas.drawRect(grassRect, grassPaint);

    // Soil (Brown bottom layer)
    final Paint soilPaint = Paint()..color = Color(0xFF8B4513); // Brown color
    final Rect soilRect =
        Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6);
    canvas.drawRect(soilRect, soilPaint);

    // Add soil texture
    final Paint soilTexturePaint = Paint()
      ..color = Color(0xFF5C3317).withOpacity(0.3) // Darker brown for texture
      ..style = PaintingStyle.fill;

    for (double x = -animationValue % 10; x < size.width; x += 10) {
      for (double y = size.height * 0.4; y < size.height; y += 10) {
        canvas.drawCircle(
            Offset(x + 5, y + 5), 3, soilTexturePaint); // Small soil dots
      }
    }

    // Grass texture (Optional blades of grass)
    final Paint grassBladePaint = Paint()
      ..color = Color(0xFF007700) // Darker green for grass blades
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double x = -animationValue % 15; x < size.width; x += 15) {
      canvas.drawLine(
        Offset(x, size.height * 0.35),
        Offset(x + 5, size.height * 0.3), // Grass blades slant
        grassBladePaint,
      );
      canvas.drawLine(
        Offset(x + 7, size.height * 0.37),
        Offset(x + 12, size.height * 0.32), // Grass blades slant
        grassBladePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class HeartRateBackgroundPainter extends CustomPainter {
  final double animationValue;

  HeartRateBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      colors: [Color(0xFFFF4D4D), Color(0xFFFF8080)], // Dark red to light red
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final Paint backgroundPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    // ECG wave
    final Paint wavePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Path wavePath = Path();
    double midHeight = size.height / 2;
    double waveLength = 100; // Length of one heartbeat cycle
    double startX =
        -animationValue % waveLength - waveLength; // Start slightly off-screen

    // Draw continuous waves
    for (double x = startX; x < size.width + waveLength; x += waveLength) {
      // P wave (small bump)
      wavePath.quadraticBezierTo(
        x + waveLength * 0.1, midHeight - 10, // Up
        x + waveLength * 0.2, midHeight, // Back to mid
      );

      // QRS Complex (sharp peak)
      wavePath.lineTo(x + waveLength * 0.3, midHeight + 5); // Small dip (Q)
      wavePath.lineTo(x + waveLength * 0.35, midHeight - 40); // Sharp peak (R)
      wavePath.lineTo(x + waveLength * 0.4, midHeight + 10); // Deep trough (S)

      // T wave (rounded bump)
      wavePath.quadraticBezierTo(
        x + waveLength * 0.5, midHeight + 20, // Up
        x + waveLength * 0.6, midHeight, // Back to mid
      );

      // Flatline before next cycle
      wavePath.lineTo(x + waveLength, midHeight);
    }

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint for animation
  }
}
