import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUserIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
    } on FirebaseAuthException catch (e) {
      print("Error: $e");
    }
  }

  bool passToggle = true;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        child: SafeArea(
            child: Column(
          children: [
            SizedBox(
              height: 150,
            ),
            Text(
              "LifeLine",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF238878),
                fontSize: 40,
                fontFamily: 'Kameron',
                fontWeight: FontWeight.bold,
                height: 0,
              ),
            ),
            SizedBox(width: 256, height: 15),
            Text(
              'Bridging Gaps, Saving Lives',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5ECD81),
                fontSize: 17,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w400,
                height: 0,
              ),
            ),
            SizedBox(height: 200),
            Padding(
              padding:
                  EdgeInsets.only(left: 30, right: 30, bottom: 20, top: 50),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color((0xFFD9D9D9)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  label: Text("Enter Email"),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 30, right: 30),
              child: TextField(
                controller: passwordController,
                obscureText: passToggle ? true : false,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color((0xFFD9D9D9)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  label: Text("Enter Password"),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: InkWell(
                    onTap: () {
                      if (passToggle == true) {
                        passToggle = false;
                      } else {
                        passToggle = true;
                      }
                      setState(() {});
                    },
                    child: passToggle
                        ? Icon(CupertinoIcons.eye_slash_fill)
                        : Icon(CupertinoIcons.eye_fill),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
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
                      onTap: signUserIn,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        child: Center(
                          child: Text(
                            "Log In",
                            style: TextStyle(
                              color: Colors.black,
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
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Dont have any account?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ));
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 23, 88, 78),
                      ),
                    ))
              ],
            ),
          ],
        )),
      ),
    );
  }
}
