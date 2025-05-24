import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.userData != null) {
      _nameController.text = widget.userData?['name'] ?? '';
     _phoneController.text = widget.userData?['phone'] != null 
    ? '0${widget.userData?['phone'].toString()}' 
    : '';

      _ageController.text = widget.userData?['age']?.toString() ?? '';
      _genderController.text = widget.userData?['gender'] ?? '';
      _addressController.text = widget.userData?['address'] ?? '';
      _roleController.text = widget.userData?['role'] ?? '';
    }
  }

  /// Update user info in Firestore
  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in! Please log in first.'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('user_info')
          .doc(user.uid)
          .set({
            'name': _nameController.text.trim(),
            'phone': int.tryParse(_phoneController.text.trim()) ?? 0,
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'gender': _genderController.text.trim(),
            'address': _addressController.text.trim(),
            'role': _roleController.text.trim(),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context); // Go back to ProfileScreen
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Name'),
                _buildTextField(
                  _phoneController,
                  'Phone',
                  isNumeric: true,
                  phoneValidator: true,
                ),
                _buildTextField(_ageController, 'Age', isNumeric: true),
                _buildTextField(_genderController, 'Gender'),
                _buildTextField(_addressController, 'Address'),
                if (widget.userData?['role'] == 'admin')
                  _buildTextField(_roleController, 'Role'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateUserInfo,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method for text fields
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
    bool phoneValidator = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (phoneValidator && !RegExp(r'^\d{11}$').hasMatch(value)) {
            return 'Please enter a valid phone number (e.g., 01680069764)';
          }
          return null;
        },
      ),
    );
  }
}
