import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:new_project/reminder/add_medicine_remindr.dart';
import 'package:new_project/reminder/edit_medicine_reminder.dart';

class MedicineReminder extends StatefulWidget {
  const MedicineReminder({super.key});

  @override
  _MedicineReminderState createState() => _MedicineReminderState();
}

class _MedicineReminderState extends State<MedicineReminder> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6FD08E),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F9F5), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('user_info')
                  .doc(_auth.currentUser?.uid)
                  .collection('medicine_reminders')
                  .orderBy('time')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 64,
                      color: Color(0xFF6FD08E),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No medicines added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToAddMedicine(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FD08E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Add Your First Medicine',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return _buildMedicineCard(
                  context,
                  data['name'] ?? 'Unknown Medicine',
                  data['dosage'] ?? '',
                  data['timeInHour'] ?? 0,
                  data['time']?.toDate(),
                  data['notes'] ?? '',
                  doc.id,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddMedicine(context),
        backgroundColor: const Color(0xFF6FD08E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

 Widget _buildMedicineCard(
  BuildContext context,
  String name,
  String dosage,
  int timeInHour,
  DateTime? time,
  String notes,
  String documentId,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFDEBD0), Color(0xFFFADADD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Card(
          color: const Color.fromARGB(255, 152, 235, 18).withOpacity(0.2),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '💊 $name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF303030),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF7F7EFF)),
                          onPressed: () => _navigateToEditMedicine(
                            context,
                            documentId,
                            name,
                            dosage,
                            timeInHour,
                            time,
                            notes,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B)),
                          onPressed: () => _showDeleteConfirmation(context, documentId),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildDetailRow(
                  Icons.medical_services_outlined,
                  'Dosage: $dosage',
                  const Color(0xFFB388FF),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.access_alarm_rounded,
                  'Interval: Every $timeInHour hrs',
                  const Color(0xFF80CBC4),
                ),

                if (time != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.schedule_rounded,
                    'Starts at: ${DateFormat.jm().format(time)}',
                    const Color(0xFF81D4FA),
                  ),
                ],

                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.sticky_note_2_outlined,
                    'Notes: $notes',
                    const Color(0xFFFFAB91),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
Widget _buildDetailRow(IconData icon, String text, Color iconColor) {
  return Row(
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withOpacity(0.15),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF444444),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
        ),
      ),
    ],
  );
}


  void _showDeleteConfirmation(BuildContext context, String documentId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Color(0xFFFF6B6B),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Reminder?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to permanently delete this medicine reminder?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteMedicine(documentId);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMedicine(String documentId) async {
    try {
      await _firestore
          .collection('user_info')
          .doc(_auth.currentUser?.uid)
          .collection('medicine_reminders')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine deleted successfully'),
          backgroundColor: Color(0xFF6FD08E),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _navigateToAddMedicine(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineReminder()),
    );
  }

  void _navigateToEditMedicine(
    BuildContext context,
    String documentId,
    String name,
    String dosage,
    int timeInHour,
    DateTime? time,
    String notes,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditMedicineReminder(
              documentId: documentId,
              initialName: name,
              initialDosage: dosage,
              initialTimeInHour: timeInHour,
              initialTime: time,
              initialNotes: notes,
              isEditing: true,
            ),
      ),
    );
  }
}
