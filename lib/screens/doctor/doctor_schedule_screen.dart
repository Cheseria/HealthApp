import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/widgets/doctor_upcoming_schedule.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  int buttonIndex = 0;
  String currentUserId = '';
  bool isLoading = true;

  final List<String> tabTitles = [
    "Upcoming",
    "Completed",
    "Canceled",
    "Requested"
  ];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      print('Current User ID: $currentUserId');

      if (currentUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in. Please log in.')),
        );
        Navigator.pop(context); // Navigate back if user is not logged in
      }
    } catch (e) {
      print('Error initializing user: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 50, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFF5ECD81),
                  fontSize: 17,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                "Schedule",
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFF238878),
                  fontSize: 40,
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTabButtons() {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff4f6fa),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  buttonIndex = index;
                });
                print('Tab selected: ${tabTitles[buttonIndex]}');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: buttonIndex == index
                      ? const Color(0xFF238878)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabTitles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: buttonIndex == index ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildScheduleContent() {
    if (currentUserId.isEmpty) {
      return const Center(
        child: Text(
          'No data available. Please log in.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return DoctorUpcomingSchedule(
      doctorId: currentUserId,
      status: tabTitles[buttonIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white, // Set background to white while loading
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Set overall background color to white
      body: Container(
        color: Colors.white, // Ensures background stays white
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            const SizedBox(height: 10),
            buildTabButtons(),
            const SizedBox(height: 10),
            Expanded(child: buildScheduleContent()),
          ],
        ),
      ),
    );
  }
}
