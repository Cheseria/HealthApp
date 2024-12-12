import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class AddMedicalResultScreen extends StatefulWidget {
  final String appointmentId;
  final String userId;

  const AddMedicalResultScreen({
    super.key,
    required this.appointmentId,
    required this.userId,
  });

  @override
  State<AddMedicalResultScreen> createState() => _AddMedicalResultScreenState();
}

class _AddMedicalResultScreenState extends State<AddMedicalResultScreen> {
  final TextEditingController resultController = TextEditingController();
  PlatformFile? selectedFile;

  Future<void> pickFile() async {
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("File picking is not supported on this platform."),
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFile = result.files.first;
        });
      } else {
        setState(() {
          selectedFile = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick file: $e")),
      );
    }
  }

  Future<void> uploadMedicalResult() async {
    final resultText = resultController.text;

    if (resultText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Medical result cannot be empty."),
        ),
      );
      return;
    }

    try {
      // Prepare data to save in Firestore
      final data = {
        'medicalResult': resultText,
        'uploadedFileName': selectedFile?.name ?? "", // Optional file name
        'uploadedFilePath': selectedFile?.path ?? "", // Optional file path
      };

      // Save medical result and optional file info to Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Medical result added successfully."),
        ),
      );
      Navigator.pop(context); // Go back to the previous screen
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding result: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medical Result"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF238878),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Medical Result",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: resultController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type medical results here...",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Document (Optional)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF238878),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
            if (selectedFile != null) ...[
              const SizedBox(height: 10),
              Text(
                "Uploaded File: ${selectedFile!.name}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238878),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                onPressed: uploadMedicalResult,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
