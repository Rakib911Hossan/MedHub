import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_project/reminder/notification.dart';

class AddMedicineReminder extends StatefulWidget {
  const AddMedicineReminder({super.key});

  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineReminder> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form fields
  String _medicineName = '';
  String _dosage = '';
  TimeOfDay _time = TimeOfDay.now();
  String _notes = '';
  int _timeInHour = 0;

  @override
  void initState() {
    super.initState();
    // _fetchMedicineReminders();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6FD08E), // Header background color
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Background color
              onSurface: Colors.black, // Text color
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white), // Background color
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<void> _fetchMedicineReminders() async {
    await NotificationService().init();

    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the user's medicine reminders from Firestore
    final remindersSnapshot =
        await FirebaseFirestore.instance
            .collection('user_info')
            .doc(userId)
            .collection('medicine_reminders')
            .get();

    if (remindersSnapshot.docs.isEmpty) {
      debugPrint('No reminders found for the user');
      return;
    }

    // Fetch the reminder IDs
    List<String> reminderIds =
        remindersSnapshot.docs.map((doc) => doc.id).toList();

    // Schedule notifications for all reminders
    for (String reminderId in reminderIds) {
      await NotificationService().scheduleNotificationFromFirestore(
        userId,
        reminderId,
      );
    }
  }
  
String generateRandomMedicineId() {
  const prefix = 'RMD';
  const length = 8; // Number of digits after 'RMD'
  final random = Random();

  final number = List.generate(length, (index) => random.nextInt(10)).join();
  return '$prefix$number';
}
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final user = _auth.currentUser;
          final newId = generateRandomMedicineId();
        if (user != null) {
          // Create a DateTime from the selected time (using today's date)
          final now = DateTime.now();
          final scheduledTime = DateTime(
              now.year, now.month, now.day, _time.hour, _time.minute);

         await _firestore
    .collection('user_info')
    .doc(user.uid)
    .collection('medicine_reminders')
    .add({
  'name': _medicineName,
  'dosage': _dosage,
  'timeInHour': _timeInHour,
  'time': scheduledTime,
  'notes': _notes,
  'createdAt': FieldValue.serverTimestamp(),
  'userId': user.uid,
  'isCompleted': false,
  'reminderId': newId,
});

// Show aesthetic success popup
_showSuccessDialog(context);

        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding medicine: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Medicine'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6FD08E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medicine Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6FD08E),
                ),
              ),
              const SizedBox(height: 24),
              _buildMedicineNameField(),
              const SizedBox(height: 20),
              _buildDosageField(),
              const SizedBox(height: 20),
              _buildTimeInHourField(),
              const SizedBox(height: 20),
              _buildTimePickerField(context),
              const SizedBox(height: 20),
              _buildNotesField(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Call both functions inside the onPressed callback
                    await _submitForm();
                    await _fetchMedicineReminders();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FD08E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Reminder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFEFFAF3),
        title: const Icon(Icons.check_circle, color: Color(0xFF6FD08E), size: 60),
        content: const Text(
          'Medicine Reminder Saved Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FD08E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
          ),
        ],
      );
    },
  );
}

  Widget _buildMedicineNameField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Medicine Name',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF6FD08E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6FD08E), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a medicine name';
        }
        return null;
      },
      onSaved: (value) => _medicineName = value!,
    );
  }

  Widget _buildTimeInHourField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Reminder after (hours)',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6FD08E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6FD08E), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the time in hour';
        }
        return null;
      },
      onSaved: (value) => _timeInHour = int.parse(value!),
    );
  }

  Widget _buildDosageField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Dosage (e.g., 1 tablet, 5mg)',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.exposure, color: Color(0xFF6FD08E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6FD08E), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the dosage';
        }
        return null;
      },
      onSaved: (value) => _dosage = value!,
    );
  }

  Widget _buildTimePickerField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF6FD08E)),
                const SizedBox(width: 16),
                Text(
                  _time.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Change',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Additional Notes (optional)',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.note_add, color: Color(0xFF6FD08E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6FD08E), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 3,
      onSaved: (value) => _notes = value ?? '',
    );
  }
}