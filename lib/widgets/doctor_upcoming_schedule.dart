import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/doctor/add_medical_result.dart';

class DoctorUpcomingSchedule extends StatelessWidget {
  final String doctorId;
  final String status;

  const DoctorUpcomingSchedule({
    super.key,
    required this.doctorId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, appointmentSnapshot) {
        if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appointmentSnapshot.hasError) {
          return Center(
              child: Text(
                  'Error loading appointments: ${appointmentSnapshot.error}'));
        }

        if (appointmentSnapshot.data?.docs.isEmpty ?? true) {
          return const Center(child: Text('No appointments found.'));
        }

        // Update past appointments if necessary
        if (status == 'Upcoming' || status == 'Requested') {
          _updatePastAppointments(appointmentSnapshot.data!.docs, status);
        }

        return ListView.builder(
          itemCount: appointmentSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final appointment = appointmentSnapshot.data!.docs[index];
            final userId = appointment['userId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError) {
                  return const Center(child: Text('Error loading user info'));
                }

                if (!userSnapshot.hasData ||
                    userSnapshot.data!.data() == null) {
                  return const Center(child: Text('User data not found'));
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['full_name'] ?? 'Unknown User';

                final appointmentDate = appointment['date'].toDate();
                final appointmentTime = appointmentDate.toLocal();

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Card(
                    elevation: 3,
                    color: const Color(0xFFF5F5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Appointment #${index + 1}",
                            style: const TextStyle(
                              color: Color(0xFF238878),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: const CircleAvatar(
                              radius: 25,
                              child: Icon(Icons.person),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')} ${appointmentTime.hour >= 12 ? 'PM' : 'AM'}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (status == 'Requested') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF238878),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Accept logic: Update status to "Upcoming"
                                    FirebaseFirestore.instance
                                        .collection('appointments')
                                        .doc(appointment.id)
                                        .update({'status': 'Upcoming'}).then(
                                            (_) {
                                      print(
                                          "Appointment ${appointment.id} accepted");
                                    }).catchError((error) {
                                      print(
                                          "Failed to accept appointment: $error");
                                    });
                                  },
                                  child: const Text("Accept"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Cancel logic
                                    FirebaseFirestore.instance
                                        .collection('appointments')
                                        .doc(appointment.id)
                                        .update({'status': 'Canceled'}).then(
                                            (_) {
                                      print("Appointment canceled");
                                    }).catchError((error) {
                                      print(
                                          "Failed to cancel appointment: $error");
                                    });
                                  },
                                  child: const Text("Cancel"),
                                ),
                              ],
                            ),
                          ],
                          if (status == 'Completed') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF238878),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Navigate to AddMedicalResultScreen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddMedicalResultScreen(
                                          appointmentId: appointment.id,
                                          userId: userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Add Medical Result"),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _updatePastAppointments(
      List<QueryDocumentSnapshot> appointments, String currentStatus) {
    final now = DateTime.now();

    for (var appointment in appointments) {
      final appointmentDate = (appointment['date'] as Timestamp).toDate();

      if (appointmentDate.isBefore(now)) {
        if (currentStatus == 'Upcoming') {
          FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointment.id)
              .update({'status': 'Completed'}).then((_) {
            print("Appointment ${appointment.id} marked as Completed");
          }).catchError((error) {
            print("Failed to update appointment: $error");
          });
        } else if (currentStatus == 'Requested') {
          FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointment.id)
              .update({'status': 'Canceled'}).then((_) {
            print("Appointment ${appointment.id} marked as Canceled");
          }).catchError((error) {
            print("Failed to update appointment: $error");
          });
        }
      }
    }
  }
}
