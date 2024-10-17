import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          SizedBox(height: 60),
          Center(
            child: Padding(
              padding: EdgeInsets.only(left: 30, right: 30, top: 30),
              child: Text(
                "${user.displayName}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF238878),
                  fontSize: 40,
                  height: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFF238878), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      "Age",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF238878),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "00",
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFF238878), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      "Weight",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF238878),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "00",
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFF238878), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      "Height",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF238878),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "00",
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 30, right: 30, top: 30),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFF238878), width: 1),
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
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
          SizedBox(height: 180),
          Padding(
            padding: EdgeInsets.only(left: 30, right: 30, top: 30),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF238878), width: 1),
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFF238878),
                  child: InkWell(
                    onTap: signUserOut,
                    child: Padding(
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
}
