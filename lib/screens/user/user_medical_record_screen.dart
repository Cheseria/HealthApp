import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthapp/screens/user/user_medical_result_screen.dart';

class MedicalRecordsScreen extends StatelessWidget {
  final String userId;

  const MedicalRecordsScreen({super.key, required this.userId});

  Future<String> getDoctorName(String doctorId) async {
    try {
      // Fetch the doctor from the users collection
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: doctorId)
          .where('role', isEqualTo: 'doctor') // Ensure it's a doctor
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        return docSnapshot.docs.first.data()['full_name'] ?? 'Unknown Doctor';
      } else {
        return 'Unknown Doctor';
      }
    } catch (e) {
      return 'Unknown Doctor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Records"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF238878),
      ),
      backgroundColor: Colors.white, // Set the background to white
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: userId)
            .where('status',
                isEqualTo: 'Completed') // Filter for completed status
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No completed appointments found."));
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index].data() as Map<String, dynamic>;
              final Timestamp? dateTimestamp = record['date'] as Timestamp?;
              final String appointmentDate = dateTimestamp != null
                  ? dateTimestamp.toDate().toString().split(' ')[0]
                  : 'Unknown Date';
              final String doctorId = record['doctorId'] ?? 'Unknown Doctor ID';
              final String medicalResult =
                  record['medicalResult'] ?? 'No medical result available.';

              // Fetch the doctor's name asynchronously
              return FutureBuilder<String>(
                future: getDoctorName(doctorId),
                builder: (context, doctorNameSnapshot) {
                  if (doctorNameSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(
                      title: Text("Loading doctor info..."),
                      subtitle: Text("Please wait"),
                    );
                  }

                  final doctorName =
                      doctorNameSnapshot.data ?? 'Unknown Doctor';

                  return ListTile(
                    title: Text("Doctor: $doctorName"),
                    subtitle: Text("Date: $appointmentDate"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Navigate to the MedicalRecordDetailScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicalRecordDetailScreen(
                            doctorName: doctorName,
                            date: appointmentDate,
                            medicalResult: medicalResult,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
