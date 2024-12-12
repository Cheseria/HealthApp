import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:healthapp/screens/user/user_medical_record_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserProfileScreen({super.key, required this.userData});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int weight = 60; // Default weight
  int height = 170; // Default height
  double bmi = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        weight = userDoc['weight'] ?? 60;
        height = userDoc['height'] ?? 170;
      });
    }
  }

  void _updateUserData() async {
    await _firestore.collection('users').doc(user.uid).set({
      'weight': weight,
      'height': height,
    }, SetOptions(merge: true));
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _calculateBMI() {
    double heightInMeters = height / 100;
    setState(() {
      bmi = weight / (heightInMeters * heightInMeters);
    });
  }

  void _showPickerDialog(String title, int min, int max, int currentValue,
      Function(int) onSelectedItemChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                    initialItem: currentValue - min),
                itemExtent: 32.0,
                onSelectedItemChanged: (int index) {
                  onSelectedItemChanged(min + index);
                },
                children: List<Widget>.generate(max - min + 1, (int index) {
                  return Center(
                    child: Text(
                      '${min + index}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                }),
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _calculateBMI();
                });
                _updateUserData(); // Save updated weight and height to Firestore
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Timestamp birthdateTimestamp = widget.userData['dob'];
    DateTime birthdate = birthdateTimestamp.toDate();
    int age = calculateAge(birthdate);
    _calculateBMI();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
              child: Text(
                "${user.displayName}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF238878),
                  fontSize: 40,
                  height: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoBox("Age", age != 0 ? "$age" : "00"),
              _buildInfoBox("Weight", "$weight", onTap: () {
                _showPickerDialog('Weight (kg)', 30, 200, weight,
                    (int newValue) {
                  setState(() {
                    weight = newValue;
                  });
                  _updateUserData();
                });
              }),
              _buildInfoBox("Height", "$height", onTap: () {
                _showPickerDialog('Height (cm)', 100, 250, height,
                    (int newValue) {
                  setState(() {
                    height = newValue;
                  });
                  _updateUserData();
                });
              }),
            ],
          ),
          const SizedBox(height: 40),
          _buildInfoBox("BMI", bmi.isNaN ? "0.0" : bmi.toStringAsFixed(1),
              width: 350),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF238878), width: 1),
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicalRecordsScreen(
                            userId: user.uid,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      child: Center(
                        child: Text(
                          "Medical Records",
                          style: TextStyle(
                            color: Color(0xFF238878),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF238878), width: 1),
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF238878),
                  child: InkWell(
                    onTap: signUserOut,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      child: Center(
                        child: Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value,
      {double width = 90, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF238878), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF238878),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
