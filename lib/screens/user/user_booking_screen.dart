import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({super.key});

  @override
  _UserBookingScreenState createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  List<Map<String, dynamic>> doctors = [];
  String? selectedDoctorId;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      // Query Firestore for users with role 'doctor'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      // Extract the data and check for any missing fields
      doctors = querySnapshot.docs
          .map((doc) => {
                'uid': doc['uid'] ??
                    '', // Ensure uid is a string, fallback if null
                'full_name':
                    doc['full_name'] ?? 'Unknown Doctor', // Fallback for name
              })
          .toList();

      setState(() {});
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  Future<void> submitBooking() async {
    if (selectedDoctorId != null &&
        selectedDate != null &&
        selectedTime != null) {
      try {
        await FirebaseFirestore.instance.collection('appointments').add({
          'uid': selectedDoctorId, // Change doctorId to uid
          'date': Timestamp.fromDate(DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              selectedTime!.hour,
              selectedTime!.minute)),
          'status': 'requested', // Set the initial status as 'requested'
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment booked successfully")),
        );
      } catch (e) {
        print("Error booking appointment: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error booking appointment")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a doctor, date, and time")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book a Doctor")),
      backgroundColor: Colors.white, // Set the background color to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedDoctorId,
              hint: const Text("Choose a Doctor"),
              items: doctors.map((doctor) {
                return DropdownMenuItem<String>(
                  value: doctor['uid'] as String, // Explicitly cast to String
                  child: Text(doctor['full_name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDoctorId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Doctor",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Date"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => pickDate(context),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(selectedTime == null
                  ? "Select Time"
                  : selectedTime!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => pickTime(context),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: submitBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 100, vertical: 20), // Increased padding
                textStyle: const TextStyle(
                    fontSize: 20), // Optional: Increase the text size
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // Optional: Rounded corners
                ),
                minimumSize: const Size(
                    double.infinity, 60), // Make the button wider and taller
              ),
              child: Text(
                "Book Appointment",
                style: TextStyle(fontSize: 20), // Increase font size
              ),
            ),
          ],
        ),
      ),
    );
  }
}
