import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userRole;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });

      final userDoc =
          await _firestore.collection('user_info').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userRole = userDoc.data()?['role'] ?? 'user';
        });
      }
    }
  }

  // Get card color based on appointment status
  Color _getCardColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.withOpacity(0.1); // Light orange for pending
      case 'confirmed':
        return Colors.green.withOpacity(0.1); // Light green for confirmed
      default:
        return Colors.grey.withOpacity(0.1); // Light grey for other statuses
    }
  }

  // Get border color based on appointment status
  Color _getBorderColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteAppointment(
    String doctorId,
    Map<String, dynamic> appointment,
  ) async {
    try {
      // First get the current doctor document to find the exact appointment match
      final doctorDoc =
          await _firestore.collection('doctors').doc(doctorId).get();
      if (!doctorDoc.exists) {
        throw Exception('Doctor document not found');
      }

      // Find the exact appointment in the array that matches all fields
      final appointments =
          doctorDoc.data()?['appointments'] as List<dynamic>? ?? [];
      Map<String, dynamic>? exactAppointment;

      for (var appt in appointments) {
        final apptMap = appt as Map<String, dynamic>;
        if (apptMap['uid'] == appointment['uid'] &&
            (apptMap['appointmentDate'] as Timestamp).toDate() ==
                (appointment['appointmentDate'] as Timestamp).toDate()) {
          exactAppointment = apptMap;
          break;
        }
      }

      if (exactAppointment == null) {
        throw Exception('Appointment not found in doctor record');
      }

      // Remove the exact matching appointment
      await _firestore.collection('doctors').doc(doctorId).update({
        'appointments': FieldValue.arrayRemove([exactAppointment]),
        'updatedAt': Timestamp.now(),
      });

      // Remove from user's appointments
      final userAppointments =
          await _firestore
              .collection('user_info')
              .doc(appointment['uid'])
              .collection('appointments')
              .where(
                'appointmentDate',
                isEqualTo: appointment['appointmentDate'],
              )
              .where('doctorId', isEqualTo: doctorId)
              .get();

      final batch = _firestore.batch();
      for (var doc in userAppointments.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.toString()}')),
      );
      debugPrint('Delete error: ${e.toString()}');
    }
  }

  Future<void> _updateStatus(
  String doctorId,
  Map<String, dynamic> appointment,
  String newStatus,
) async {
  try {
    // 1. Get the current doctor document
    final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
    if (!doctorDoc.exists) {
      throw Exception('Doctor document not found');
    }

    // 2. Find the exact appointment in the array
    final appointments = doctorDoc.data()?['appointments'] as List<dynamic>? ?? [];
    int? appointmentIndex;
    Map<String, dynamic>? existingAppointment;
    
    for (int i = 0; i < appointments.length; i++) {
      final appt = appointments[i] as Map<String, dynamic>;
      if (appt['uid'] == appointment['uid'] &&
          (appt['appointmentDate'] as Timestamp).toDate() == 
          (appointment['appointmentDate'] as Timestamp).toDate() &&
          appt['status'] == 'pending') {  // Only update pending appointments
        appointmentIndex = i;
        existingAppointment = appt;
        break;
      }
    }

    if (existingAppointment == null) {
      throw Exception('Pending appointment not found in doctor record');
    }

    // 3. Create updated appointment data
    final updatedAppointment = Map<String, dynamic>.from(existingAppointment);
    updatedAppointment['status'] = newStatus;

    // 4. Get the entire appointments array
    List<dynamic> updatedAppointments = List.from(appointments);
    
    // 5. Replace the specific appointment
    updatedAppointments[appointmentIndex!] = updatedAppointment;

    // 6. Update the entire array at once
    await _firestore.collection('doctors').doc(doctorId).update({
      'appointments': updatedAppointments,
      'updatedAt': Timestamp.now(),
    });

    // 7. Update in user's appointments
    final userAppointments = await _firestore
        .collection('user_info')
        .doc(appointment['uid'])
        .collection('appointments')
        .where('appointmentDate', isEqualTo: appointment['appointmentDate'])
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .get();

    final batch = _firestore.batch();
    for (var doc in userAppointments.docs) {
      batch.update(doc.reference, {'status': newStatus});
    }
    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment status updated to $newStatus')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update: ${e.toString()}')),
    );
    debugPrint('Update error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Combine all appointments from all doctors
          List<Map<String, dynamic>> allAppointments = [];
          List<String> doctorIds = [];

          for (var doctorDoc in snapshot.data!.docs) {
            final appointments =
                doctorDoc['appointments'] as List<dynamic>? ?? [];
            for (var appt in appointments) {
              allAppointments.add({
                ...appt as Map<String, dynamic>,
                'doctorId': doctorDoc.id,
              });
            }
            doctorIds.add(doctorDoc.id);
          }

          // Filter based on user role
          final filteredAppointments =
              allAppointments.where((appt) {
                if (_userRole == 'admin') {
                  return appt['status'] == 'pending' || appt['status'] == 'confirmed';
                } else {
                  return appt['uid'] == _currentUserId;
                }
              }).toList();

          if (filteredAppointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _userRole == 'admin'
                        ? 'No pending appointments'
                        : 'You have no appointments',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredAppointments.length,
            itemBuilder: (context, index) {
              final appointment = filteredAppointments[index];
              final doctorId = appointment['doctorId'];
              final appointmentDate =
                  (appointment['appointmentDate'] as Timestamp).toDate();
              final status = appointment['status'] ?? 'pending';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getBorderColor(status),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  color: _getCardColor(status),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _getBorderColor(status).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Appointment Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 51, 48, 48),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getBorderColor(
                                  status,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getBorderColor(
                                    status,
                                  ).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _getBorderColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Patient info
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Patient',
                          value: appointment['patientName'] ?? 'No Name',
                          isBold: true,
                        ),

                        const Divider(height: 24, thickness: 0.5),

                        // Doctor info
                        _buildInfoRow(
                          icon: Icons.medical_services_outlined,
                          label: 'Doctor',
                          value: appointment['doctorName'] ?? 'Unknown Doctor',
                        ),

                        const SizedBox(height: 8),

                        // Specialty
                        _buildInfoRow(
                          icon: Icons.work_outline,
                          label: 'Specialty',
                          value: appointment['speciality'] ?? 'General',
                        ),

                        const Divider(height: 24, thickness: 0.5),

                        // Date and time row - now with overflow protection
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 400;
                            return isWide
                                ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoRow(
                                        icon: Icons.calendar_today_outlined,
                                        label: 'Date',
                                        value: DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(appointmentDate),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInfoRow(
                                        icon: Icons.access_time_outlined,
                                        label: 'Time',
                                        value: DateFormat(
                                          'h:mm a',
                                        ).format(appointmentDate),
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  children: [
                                    _buildInfoRow(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Date',
                                      value: DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(appointmentDate),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      icon: Icons.access_time_outlined,
                                      label: 'Time',
                                      value: DateFormat(
                                        'h:mm a',
                                      ).format(appointmentDate),
                                    ),
                                  ],
                                );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Action buttons - fixed overflow
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            if (_userRole == 'admin' && status == 'pending')
                              SizedBox(
                                width: 120, // Fixed width for buttons
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Confirm'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color.fromARGB(255, 23, 94, 25),
                                    side: const BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed:
                                      () => _updateStatus(
                                        doctorId,
                                        appointment,
                                        'confirmed',
                                      ),
                                ),
                              ),
                            SizedBox(
                              width: 120, // Fixed width for buttons
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color.fromARGB(255, 138, 29, 21),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onPressed:
                                    () => _deleteAppointment(
                                      doctorId,
                                      appointment,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color.fromARGB(255, 27, 27, 27)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 51, 50, 50)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color.fromARGB(255, 43, 42, 42) : const Color.fromARGB(255, 10, 9, 9),
          ),
        ),
      ],
    );
  }
}
