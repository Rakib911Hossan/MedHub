import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditDoctorProfile extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> existingData;

  const EditDoctorProfile({Key? key, required this.doctorId, required this.existingData}) : super(key: key);

  @override
  _EditDoctorProfileState createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _hospitalController;
  late TextEditingController _appointmentLink;
  List<String> _selectedDays = [];
  String _availableTime = '';
  String _gender = 'Male';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingData['name']);
    _specialtyController = TextEditingController(text: widget.existingData['specialty']);
    _phoneController = TextEditingController(text: widget.existingData['phone']);
    _emailController = TextEditingController(text: widget.existingData['email']);
    _hospitalController = TextEditingController(text: widget.existingData['hospital']);
    _appointmentLink = TextEditingController(text: widget.existingData['appointmentLink']);
    _availableTime = widget.existingData['availableTime'] ?? '';
    _selectedDays = List<String>.from(widget.existingData['availableDays'] ?? []);
    _gender = widget.existingData['gender'] ?? 'Male';
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateDoctorProfile() async {
    await _firestore.collection('doctors').doc(widget.doctorId).update({
      'name': _nameController.text,
      'specialty': _specialtyController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'hospital': _hospitalController.text,
      'availableDays': _selectedDays,
      'availableTime': _availableTime,
      'appointmentLink': _appointmentLink.text,
      'profileImage': _selectedImage?.path ?? widget.existingData['profileImage'],
      'gender': _gender,
      'updatedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Doctor profile updated successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Doctor Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (widget.existingData['profileImage'] != null && widget.existingData['profileImage'].isNotEmpty
                          ? NetworkImage(widget.existingData['profileImage']) as ImageProvider
                          : const AssetImage('assets/default_profile.png')), // Provide default image
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Doctor's Name")),
              TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: "Specialty")),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone")),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: _hospitalController, decoration: const InputDecoration(labelText: "Hospital")),
              TextField(controller: _appointmentLink, decoration: const InputDecoration(labelText: "Appointment Link")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateDoctorProfile,
                child: const Text("Update Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
