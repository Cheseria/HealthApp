import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:healthapp/screens/user_home_screen.dart';
import 'package:healthapp/screens/user_messages_screen.dart';
import 'package:healthapp/screens/user_profile_screen.dart';
import 'package:healthapp/screens/user_schedule_screen.dart';

class UserNavbarRoots extends StatefulWidget {
  final Map<String, dynamic> userData;

  UserNavbarRoots({required this.userData});
  @override
  State<UserNavbarRoots> createState() => _UserNavbarRootsState();
}

class _UserNavbarRootsState extends State<UserNavbarRoots> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      UserHomeScreen(),
      UserScheduleScreen(),
      UserMessagesScreen(),
      UserProfileScreen(userData: widget.userData),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: screens[selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 10.0, vertical: 20), // Padding from the edges
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the navbar
            borderRadius: BorderRadius.circular(30), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black26, // Shadow color
                blurRadius: 15, // Spread of the shadow
                offset: Offset(0, 10), // Shadow position (below the navbar)
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
            child: GNav(
              gap: 8,
              color: Color(0xFF238878), // Inactive icon color
              activeColor: Colors.white, // Active icon color
              tabBackgroundColor:
                  Color(0xFF238878), // Active tab background color
              padding: const EdgeInsets.all(15), // Padding inside the tabs
              onTabChange: (Index) {
                setState(() {
                  selectedIndex = Index;
                });
              },
              tabs: const [
                GButton(
                  icon: Icons.home_filled,
                  text: "Home",
                ),
                GButton(
                  icon: Icons.calendar_month,
                  text: "Schedule",
                ),
                GButton(
                  icon: CupertinoIcons.chat_bubble_text_fill,
                  text: "Messages",
                ),
                GButton(
                  icon: CupertinoIcons.profile_circled,
                  text: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
