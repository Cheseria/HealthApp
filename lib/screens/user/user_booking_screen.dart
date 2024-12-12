import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBookingScreen extends StatefulWidget {
  final String? appointmentId; // For rescheduling
  final String? initialDoctorId;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const UserBookingScreen({
    super.key,
    this.appointmentId,
    this.initialDoctorId,
    this.initialDate,
    this.initialTime,
  });

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

    // Pre-fill values for rescheduling
    selectedDoctorId = widget.initialDoctorId;
    selectedDate = widget.initialDate;
    selectedTime = widget.initialTime;

    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      // Fetch doctors from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor') // Filter for doctors
          .get();

      // Map query results to a list of doctors
      doctors = querySnapshot.docs
          .map((doc) => {
                'uid': doc['uid'] ?? '',
                'full_name': doc['full_name'] ?? 'Unknown Doctor',
              })
          .toList();

      setState(() {});
    } catch (e) {
      print("Error fetching doctors: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load doctors")),
      );
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF238878), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Color(0xFF238878), // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF238878), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final List<TimeOfDay> availableTimes = _generate30MinuteIntervals();
    TimeOfDay? pickedTime;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Time"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: availableTimes.length,
              itemBuilder: (context, index) {
                final time = availableTimes[index];
                return ListTile(
                  title: Text(
                    time.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    pickedTime = time;
                    Navigator.pop(context); // Close the dialog
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

// Generate time intervals of 30 minutes
  List<TimeOfDay> _generate30MinuteIntervals() {
    final List<TimeOfDay> times = [];
    for (int hour = 0; hour < 24; hour++) {
      times.add(TimeOfDay(hour: hour, minute: 0)); // Add :00
      times.add(TimeOfDay(hour: hour, minute: 30)); // Add :30
    }
    return times;
  }

  Future<void> submitBooking() async {
    if (selectedDoctorId == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a doctor, date, and time")),
      );
      return;
    }

    try {
      // Combine date and time into a single `Timestamp`
      final appointmentTimestamp = Timestamp.fromDate(
        DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        ),
      );

      if (widget.appointmentId != null) {
        // Rescheduling existing appointment: Update only the date
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .update({
          'date': appointmentTimestamp, // Only update the date
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment rescheduled successfully")),
        );
      } else {
        // Creating a new appointment
        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserUid == null) {
          throw Exception("No user is logged in.");
        }

        await FirebaseFirestore.instance.collection('appointments').add({
          'doctorId': selectedDoctorId,
          'userId': currentUserUid,
          'date': appointmentTimestamp,
          'status': 'Requested', // Default status for new appointments
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment booked successfully")),
        );
      }

      Navigator.pop(context); // Return to the previous screen
    } catch (e) {
      print("Error submitting booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting booking: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: Text(
          widget.appointmentId != null
              ? "Reschedule Appointment"
              : "Book a Doctor",
          style: const TextStyle(
            color: Color(0xFF238878), // Change text color
          ),
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        elevation: 0, // Remove AppBar shadow
        iconTheme: const IconThemeData(color: Color(0xFF238878)), // Icon color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Doctor dropdown
            DropdownButtonFormField<String>(
              value: selectedDoctorId,
              hint: const Text("Choose a Doctor"),
              items: doctors.map((doctor) {
                return DropdownMenuItem<String>(
                  value: doctor['uid'] as String,
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

            // Date picker
            ListTile(
              title: Text(
                selectedDate == null
                    ? "Select Date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                style: const TextStyle(
                  color: Colors.black, // Set text color
                ),
              ),
              trailing:
                  const Icon(Icons.calendar_today, color: Color(0xFF238878)),
              onTap: () => pickDate(context),
            ),
            const SizedBox(height: 20),

            // Time picker
            ListTile(
              title: Text(
                selectedTime == null
                    ? "Select Time"
                    : selectedTime!.format(context),
                style: const TextStyle(
                  color: Colors.black, // Set text color
                ),
              ),
              trailing: const Icon(Icons.access_time, color: Color(0xFF238878)),
              onTap: () => pickTime(context),
            ),
            const SizedBox(height: 40),

            // Submit button
            ElevatedButton(
              onPressed: submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300], // Set button to light grey
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                textStyle: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF238878), // Set button text color
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.appointmentId != null
                    ? "Reschedule Appointment"
                    : "Book Appointment",
                style: const TextStyle(color: Color(0xFF238878)), // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
