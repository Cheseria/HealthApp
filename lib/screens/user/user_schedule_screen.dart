import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/user/user_booking_screen.dart';
import 'package:healthapp/widgets/upcoming_schedule.dart';

class UserScheduleScreen extends StatefulWidget {
  const UserScheduleScreen({super.key});

  @override
  State<UserScheduleScreen> createState() => _UserScheduleScreenState();
}

class _UserScheduleScreenState extends State<UserScheduleScreen> {
  int buttonIndex = 0;
  String currentUserId = '';

  final List<String> tabTitles = [
    "Upcoming",
    "Completed",
    "Canceled",
    "Requested"
  ];

  @override
  void initState() {
    super.initState();
    currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? ''; // Get the user ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
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
                Container(
                  padding: const EdgeInsets.all(20),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserBookingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    color: const Color(0xFF238878),
                    iconSize: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
                          color: buttonIndex == index
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: UpcomingSchedule(
              userId: currentUserId,
              status: tabTitles[buttonIndex],
            ),
          ),
        ],
      ),
    );
  }
}
