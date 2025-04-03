import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/doctors/edit_doctors_profile.dart';

class AddDoctorsProfile extends StatefulWidget {
  const AddDoctorsProfile({Key? key}) : super(key: key);

  @override
  _AddDoctorsProfileState createState() => _AddDoctorsProfileState();
}

class _AddDoctorsProfileState extends State<AddDoctorsProfile> {

 final User? user = FirebaseAuth.instance.currentUser;
  String userRole = '';
  String userName = '';
  String userId = '';
  String userEmail = '';
  String userPhone = '';


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _appointmentLink = TextEditingController();
  final List<String> _selectedDays = [];
  final List<String> _weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

 

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('user_info')
                .doc(user!.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            userRole = userDoc['role'] ?? 'user';
            userName =
                userDoc['name'] ??
                user?.displayName ??
                user?.email?.split('@').first ??
                'User';
            userId = user!.uid;
            userEmail = user?.email ?? '';
            userPhone = userDoc['phone'].toString();
                 _nameController.text = userName;
          _phoneController.text = '0$userPhone';
          _emailController.text = userEmail;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        setState(() {
          userName = user?.email?.split('@').first ?? 'User';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  File? _selectedImage;
  String _gender = 'Male'; // Default gender selection
  String _availableTime = ''; // Available time will be stored here
  
  // Function to pick the start and end times for the available time
  Future<void> _selectAvailableTime() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (endTime == null) return;

    setState(() {
      _availableTime = '${startTime.format(context)} - ${endTime.format(context)}';
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildImageSection() {
    return Center(
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackImage(),
                    )
                  : _buildFallbackImage(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 18,
                child: Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset('lib/assets/order_medicine.jpg', fit: BoxFit.cover);
  }

  // Function to show success popup
  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text("Doctor profile added successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the popup
                Navigator.pop(context); // Navigate back to previous screen
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _addDoctorProfile() async {
  if (_nameController.text.isEmpty ||
      _specialtyController.text.isEmpty ||
      _phoneController.text.isEmpty ||
      _emailController.text.isEmpty ||
      _hospitalController.text.isEmpty ||
      _availableTime.isEmpty ||
      _appointmentLink.text.isEmpty ||
      _selectedDays.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill in all fields")),
    );
    return;
  }

  // If no existing profile, add new profile
  await _firestore.collection('doctors').add({
    'name': _nameController.text,
    'specialty': _specialtyController.text,
    'phone': _phoneController.text,
    'email': _emailController.text,
    'hospital': _hospitalController.text,
    'availableDays': _selectedDays,
    'availableTime': _availableTime,
    'appointmentLink': _appointmentLink.text,
    'profileImage': _selectedImage?.path ?? '',
    'gender': _gender,
    'appointments': [],
    'doctorId': userId,
    'isAvailable': true,
    'createdAt': Timestamp.now(),
  });

  _showSuccessPopup();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Doctor Profile"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 225, 231, 243), const Color.fromARGB(255, 212, 231, 240)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Doctor's Name"),
                ),
                TextField(
                  controller: _specialtyController,
                  decoration: const InputDecoration(labelText: "Specialty"),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _hospitalController,
                  decoration: const InputDecoration(labelText: "Hospital"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _appointmentLink,
                  decoration: const InputDecoration(labelText: "Appointment Link"),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                const Text("Available Time"),
                GestureDetector(
                  onTap: _selectAvailableTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _availableTime.isEmpty ? "Select Available Time" : _availableTime,
                      style: TextStyle(
                        color: _availableTime.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Available Days"),
                Wrap(
                  spacing: 8.0,
                  children: _weekdays.map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: _selectedDays.contains(day),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text("Gender"),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Male',
                      groupValue: _gender,
                      onChanged: (String? value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                    const Text("Male"),
                    Radio<String>(
                      value: 'Female',
                      groupValue: _gender,
                      onChanged: (String? value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                    const Text("Female"),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addDoctorProfile,
                  child: const Text("Add Doctor"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
