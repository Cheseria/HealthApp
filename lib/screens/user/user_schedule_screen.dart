import 'package:flutter/material.dart';
import 'package:healthapp/widgets/upcoming_schedule.dart';

class UserScheduleScreen extends StatefulWidget {
  @override
  State<UserScheduleScreen> createState() => _UserScheduleScreenState();
}

class _UserScheduleScreenState extends State<UserScheduleScreen> {
  int buttonIndex = 0;

  final scheduleWidgets = [
    UpcomingSchedule(),
    Center(
      child: Text("Completed"),
    ),
    Center(
      child: Text("Canceled"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 50, left: 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Your',
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
                "Schedule",
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
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Color(0xfff4f6fa),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      buttonIndex = 0;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    decoration: BoxDecoration(
                      color: buttonIndex == 0
                          ? Color(0xFF238878)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Upcoming",
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
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: buttonIndex == 1
                          ? Color(0xFF238878)
                          : Colors.transparent,
                    ),
                    child: Text(
                      "Completed",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: buttonIndex == 1 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      buttonIndex = 2;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: buttonIndex == 2
                          ? Color(0xFF238878)
                          : Colors.transparent,
                    ),
                    child: Text(
                      "Canceled",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: buttonIndex == 2 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          scheduleWidgets[buttonIndex],
        ],
      ),
    );
  }
}
