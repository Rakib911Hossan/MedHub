import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditMedicineReminder extends StatefulWidget {
  final String documentId;
  final String initialName;
  final String initialDosage;
  final DateTime? initialTime;
  final String initialNotes;
  final bool isEditing;

  const EditMedicineReminder({
    Key? key,
    required this.documentId,
    required this.initialName,
    required this.initialDosage,
    required this.initialTime,
    required this.initialNotes,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _EditMedicineReminderState createState() => _EditMedicineReminderState();
}

class _EditMedicineReminderState extends State<EditMedicineReminder> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String _medicineName;
  late String _dosage;
  late TimeOfDay _time;
  late String _notes;

  @override
  void initState() {
    super.initState();
    _medicineName = widget.initialName;
    _dosage = widget.initialDosage;
    _time = widget.initialTime != null
        ? TimeOfDay.fromDateTime(widget.initialTime!)
        : TimeOfDay.now();
    _notes = widget.initialNotes;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final user = _auth.currentUser;
        if (user != null) {
          final now = DateTime.now();
          final updatedTime = DateTime(
              now.year, now.month, now.day, _time.hour, _time.minute);

          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('medicineReminders')
              .doc(widget.documentId)
              .update({
            'name': _medicineName,
            'dosage': _dosage,
            'time': updatedTime,
            'notes': _notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating medicine: ${e.toString()}'),
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
        title: Text(widget.isEditing ? 'Edit Medicine' : 'Add Medicine'),
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
              _buildTimePickerField(context),
              const SizedBox(height: 20),
              _buildNotesField(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FD08E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update Reminder',
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

  Widget _buildMedicineNameField() {
    return TextFormField(
      initialValue: _medicineName,
      decoration: _inputDecoration('Medicine Name', Icons.medical_services),
      validator: (value) => value == null || value.isEmpty
          ? 'Please enter a medicine name'
          : null,
      onSaved: (value) => _medicineName = value!,
    );
  }

  Widget _buildDosageField() {
    return TextFormField(
      initialValue: _dosage,
      decoration: _inputDecoration('Dosage (e.g., 1 tablet)', Icons.exposure),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter the dosage' : null,
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
      initialValue: _notes,
      decoration: _inputDecoration('Additional Notes (optional)', Icons.note_add),
      maxLines: 3,
      onSaved: (value) => _notes = value ?? '',
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Color(0xFF6FD08E)),
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
    );
  }
}
