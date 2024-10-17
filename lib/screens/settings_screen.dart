import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/auth_screen.dart';
import 'package:healthapp/widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          child: Column(
            children: [
              Row(children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthScreen(),
                        ));
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 70),
                Text(
                  "Settings",
                  style: TextStyle(
                      color: Color(0xFF238878),
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
              ]),
              SizedBox(height: 40),
              SettingsTile(
                  color: Colors.teal, icon: Icons.person, title: "Account"),
              SizedBox(height: 20),
              SettingsTile(
                  color: Colors.green,
                  icon: Icons.edit,
                  title: "Edit Information"),
              SizedBox(height: 20),
              SettingsTile(
                  color: Colors.black,
                  icon: Icons.notifications,
                  title: "Notification"),
              SizedBox(height: 20),
              SettingsTile(
                  color: Colors.blue,
                  icon: Icons.help_outline_rounded,
                  title: "Help"),
            ],
          ),
        ),
      ),
    );
  }
}
