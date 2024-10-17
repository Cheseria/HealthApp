import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/auth_screen.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool passToggle = true;

  final fullnamecontroller = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedRole;

  Future<void> signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text, password: passwordController.text);

      User? user = userCredential.user;

      if (user != null) {
        String uid = user.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'full_name': fullnamecontroller.text,
          'email': emailController.text,
          'phone_number': phoneNumberController.text,
          'dob': dobController.text, // Store Date of Birth
          'role': selectedRole,
          'uid': uid,
        });

        await user.updateProfile(displayName: fullnamecontroller.text);

        await user.reload();
      }
      ;
      print('User signed up and data saved to Firestore!');
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthScreen(),
          ));
    } on FirebaseAuthException catch (e) {
      print('Error : ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error during sign up')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dobController.text =
            DateFormat('yyyy-MM-dd').format(picked); // Format the selected date
      });
    }
  }

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
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                "Sign up for ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF238878),
                  fontSize: 40,
                  height: 0,
                ),
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
            ]),
            SizedBox(height: 100),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: "Select Role",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'doctor',
                    child: Container(
                      width: double
                          .infinity, // Ensures it matches the field's width
                      child: Text('Doctor'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'patient',
                    child: Container(
                      width: double
                          .infinity, // Ensures it matches the field's width
                      child: Text('Patient'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: TextField(
                controller: fullnamecontroller,
                decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: TextField(
                controller: dobController,
                readOnly: true,
                onTap: () {
                  _selectDate(context);
                },
                decoration: InputDecoration(
                  labelText: "Date of Birth",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: "Email Adress",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: TextField(
                controller: passwordController,
                obscureText: passToggle ? true : false,
                decoration: InputDecoration(
                  labelText: "Email Password",
                  border: OutlineInputBorder(),
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
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF238878), width: 1),
                  ),
                  child: InkWell(
                    onTap: signUp,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      child: Center(
                        child: Text(
                          "Create Account",
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have account?",
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
                            builder: (context) => AuthScreen(),
                          ));
                    },
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 23, 88, 78),
                      ),
                    ))
              ],
            )
          ],
        )),
      ),
    );
  }
}
