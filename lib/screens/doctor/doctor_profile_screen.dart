import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DoctorProfileScreen({required this.userData, Key? key})
      : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.userData['description'] ?? '';
    _fetchPhoneNumber();
  }

  Future<void> _fetchPhoneNumber() async {
    try {
      // Fetch phone number from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          phoneNumber = doc['phone_number'] ?? 'No Phone';
        });
      } else {
        setState(() {
          phoneNumber = 'No Phone';
        });
      }
    } catch (e) {
      setState(() {
        phoneNumber = 'Error fetching phone';
      });
    }
  }

  void _saveDescription() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'description': _descriptionController.text,
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Description saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save description: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF238878),
        title: Text(
          'Doctor Profile',
        ),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 25),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Image Placeholder
              CircleAvatar(
                radius: 60,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : AssetImage('assets/placeholder.jpeg') as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
              SizedBox(height: 20),

              // Doctor Name
              Text(
                user.displayName ?? 'Doctor Name',
                style: TextStyle(
                  color: Color(0xFF238878),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Description Field
              _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      _descriptionController.text.isNotEmpty
                          ? _descriptionController.text
                          : 'No description provided.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
              SizedBox(height: 20),

              // Save or Edit Button
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveDescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF238878),
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save Description'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF238878),
                  ),
                  child: Text(
                    'Edit Description',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              SizedBox(height: 20),

              // Contact Information
              Row(
                children: [
                  Icon(Icons.email, color: Color(0xFF238878)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.email ?? 'No Email',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.phone, color: Color(0xFF238878)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      phoneNumber ?? 'Loading phone number...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Log Out Button
              ElevatedButton(
                onPressed: signUserOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
