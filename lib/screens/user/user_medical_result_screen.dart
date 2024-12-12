import 'package:flutter/material.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final String doctorName;
  final String date;
  final String medicalResult;

  const MedicalRecordDetailScreen({
    super.key,
    required this.doctorName,
    required this.date,
    required this.medicalResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Record Details"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF238878),
      ),
      backgroundColor: Colors.white, // Set the background to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Doctor: $doctorName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Date: $date",
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const Text(
              "Medical Result:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  medicalResult,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
