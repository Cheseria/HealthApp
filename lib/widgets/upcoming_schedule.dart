import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/screens/user/user_booking_screen.dart';

class UpcomingSchedule extends StatelessWidget {
  final String userId;
  final String status;

  const UpcomingSchedule({
    super.key,
    required this.userId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: userId)
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

        // Update past Requested appointments to "Canceled"
        if (status == 'Requested') {
          _updatePastAppointments(appointmentSnapshot.data!.docs);
        }

        return ListView.builder(
          itemCount: appointmentSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final appointment = appointmentSnapshot.data!.docs[index];
            final doctorId = appointment['doctorId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(doctorId)
                  .get(),
              builder: (context, doctorSnapshot) {
                if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (doctorSnapshot.hasError) {
                  return const Center(
                      child: Text('Error loading doctor information'));
                }

                if (!doctorSnapshot.hasData ||
                    doctorSnapshot.data!.data() == null) {
                  return const Center(
                      child: Text('Doctor information not found'));
                }

                final doctorData =
                    doctorSnapshot.data!.data() as Map<String, dynamic>;
                final doctorName = doctorData['full_name'] ?? 'Unknown Doctor';

                final appointmentDate =
                    (appointment['date'] as Timestamp).toDate();
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
                              doctorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text("Doctor"),
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
                                    // Navigate to UserBookingScreen for rescheduling
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserBookingScreen(
                                          appointmentId: appointment.id,
                                          initialDoctorId: doctorId,
                                          initialDate: appointmentDate,
                                          initialTime: TimeOfDay.fromDateTime(
                                              appointmentDate),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Reschedule"),
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
                                    // Cancel appointment
                                    _cancelAppointment(appointment.id);
                                  },
                                  child: const Text("Cancel"),
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

  // Method to update past Requested appointments to "Canceled"
  void _updatePastAppointments(List<QueryDocumentSnapshot> appointments) {
    final now = DateTime.now();

    for (var appointment in appointments) {
      final appointmentDate = (appointment['date'] as Timestamp).toDate();

      if (appointmentDate.isBefore(now)) {
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

  // Method to cancel an appointment
  void _cancelAppointment(String appointmentId) {
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': 'Canceled'}).then((_) {
      print("Appointment $appointmentId canceled successfully");
    }).catchError((error) {
      print("Failed to cancel appointment: $error");
    });
  }
}
