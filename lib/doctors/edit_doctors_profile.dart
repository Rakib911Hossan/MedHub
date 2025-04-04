import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditDoctorProfile extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> existingData;

  const EditDoctorProfile({
    Key? key,
    required this.doctorId,
    required this.existingData,
  }) : super(key: key);

  @override
  _EditDoctorProfileState createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _weekdays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _hospitalController;
  late TextEditingController _appointmentLink;
  late TextEditingController _consultationFeeController;
  late List<String> _selectedDays;
  late String _availableTime;
  late String _gender;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingData['name']);
    _specialtyController = TextEditingController(
      text: widget.existingData['specialty'],
    );
    _phoneController = TextEditingController(
      text: widget.existingData['phone'],
    );
    _emailController = TextEditingController(
      text: widget.existingData['email'],
    );
    _hospitalController = TextEditingController(
      text: widget.existingData['hospital'],
    );
    _appointmentLink = TextEditingController(
      text: widget.existingData['appointmentLink'],
    );
    _consultationFeeController = TextEditingController(
      text: widget.existingData['consultationFee'],
    );
    _availableTime = widget.existingData['availableTime'] ?? '';
    _selectedDays = List<String>.from(
      widget.existingData['availableDays'] ?? [],
    );
    _gender = widget.existingData['gender'] ?? 'Male';

    _selectedImage =
        widget.existingData['profileImage'] != null
            ? File(widget.existingData['profileImage'])
            : null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
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
              child:
                  _selectedImage != null
                      ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackImage(),
                      )
                      : (widget.existingData['profileImage'] != null &&
                              widget.existingData['profileImage'].isNotEmpty
                          ? Image.network(
                            widget.existingData['profileImage'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackImage(),
                          )
                          : _buildFallbackImage()),
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
      _availableTime =
          '${startTime.format(context)} - ${endTime.format(context)}';
    });
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text("Doctor profile updated successfully."),
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

  Future<void> _updateDoctorProfile() async {
    if (_nameController.text.isEmpty ||
        _specialtyController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _hospitalController.text.isEmpty ||
        _availableTime.isEmpty ||
        _appointmentLink.text.isEmpty ||
        _consultationFeeController.text.isEmpty ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    await _firestore.collection('doctors').doc(widget.doctorId).update({
      'name': _nameController.text,
      'specialty': _specialtyController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'hospital': _hospitalController.text,
      'availableDays': _selectedDays,
      'availableTime': _availableTime,
      'appointmentLink': _appointmentLink.text,
      'consultationFee': _consultationFeeController.text,
      'profileImage':
          _selectedImage?.path ?? widget.existingData['profileImage'],
      'gender': _gender,
      'updatedAt': Timestamp.now(),
    });

    _showSuccessPopup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Doctor Profile"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 225, 231, 243),
              const Color.fromARGB(255, 212, 231, 240),
            ],
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
                  decoration: const InputDecoration(
                    labelText: "Doctor's Name",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _specialtyController,
                  decoration: const InputDecoration(
                    labelText: "Specialty",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _hospitalController,
                  decoration: const InputDecoration(
                    labelText: "Hospital",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _appointmentLink,
                  decoration: const InputDecoration(
                    labelText: "Appointment Link",
                    hintText: "https://example.com/appointment",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _consultationFeeController,
                  decoration: const InputDecoration(
                    labelText: "Consultation Fee",
                    prefixText: "BDT ", // Adds "BDT " inside the input field
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 10),
                const Text("Available Time"),
                GestureDetector(
                  onTap: _selectAvailableTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _availableTime.isEmpty
                          ? "Select Available Time"
                          : _availableTime,
                      style: TextStyle(
                        color:
                            _availableTime.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Available Days"),
                Wrap(
                  spacing: 8.0,
                  children:
                      _weekdays.map((day) {
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
                  onPressed: _updateDoctorProfile,
                  child: const Text("Update Profile"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
