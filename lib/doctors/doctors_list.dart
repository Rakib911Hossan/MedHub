import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorsList extends StatefulWidget {
  const DoctorsList({super.key});

  @override
  _DoctorsListState createState() => _DoctorsListState();
}

class _DoctorsListState extends State<DoctorsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, List<DocumentSnapshot>> _groupedDoctors = {};
  Map<String, List<DocumentSnapshot>> _filteredDoctors = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchAppointmentLink(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMMM d, y - h:mm a').format(timestamp.toDate());
  }

  void _groupDoctorsBySpecialty(List<DocumentSnapshot> doctors) {
    final grouped = <String, List<DocumentSnapshot>>{};

    for (var doctor in doctors) {
      final data = doctor.data() as Map<String, dynamic>;
      final specialty = data['specialty'] ?? 'Other';

      if (!grouped.containsKey(specialty)) {
        grouped[specialty] = [];
      }
      grouped[specialty]!.add(doctor);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _groupedDoctors = grouped;
          _filteredDoctors = _filterDoctors(grouped);
        });
      }
    });
  }

  Map<String, List<DocumentSnapshot>> _filterDoctors(
    Map<String, List<DocumentSnapshot>> doctors,
  ) {
    if (_searchQuery.isEmpty) return doctors;

    final filtered = <String, List<DocumentSnapshot>>{};

    for (var entry in doctors.entries) {
      final specialty = entry.key;
      final filteredDoctors =
          entry.value.where((doctor) {
            final data = doctor.data() as Map<String, dynamic>;
            final name = data['name']?.toString().toLowerCase() ?? '';
            final hospital = data['hospital']?.toString().toLowerCase() ?? '';
            final doctorSpecialty =
                data['specialty']?.toString().toLowerCase() ?? '';

            return name.contains(_searchQuery) ||
                hospital.contains(_searchQuery) ||
                doctorSpecialty.contains(_searchQuery);
          }).toList();

      if (filteredDoctors.isNotEmpty) {
        filtered[specialty] = filteredDoctors;
      }
    }

    return filtered;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            hintText: 'Search by name, specialty or hospital...',
            prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _filteredDoctors = _groupedDoctors;
                        });
                        FocusScope.of(context).unfocus();
                      },
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
              _filteredDoctors = _filterDoctors(_groupedDoctors);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors List'),
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
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('doctors').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No doctors found'));
                  }

                  if (_groupedDoctors.isEmpty ||
                      snapshot.data!.docs.length !=
                          _groupedDoctors.values.fold(
                            0,
                            (sum, list) => sum + list.length,
                          )) {
                    _groupDoctorsBySpecialty(snapshot.data!.docs);
                  }

                  if (_filteredDoctors.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                      child: Text('No matching doctors found'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final specialty = _filteredDoctors.keys.elementAt(index);
                      final doctors = _filteredDoctors[specialty]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          ...doctors.map((doctor) {
                            var data = doctor.data() as Map<String, dynamic>;

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey[200],
                                          backgroundImage:
                                              data['profileImage'] != null &&
                                                      data['profileImage']
                                                          .isNotEmpty
                                                  ? FileImage(
                                                    File(data['profileImage']),
                                                  ) // Use FileImage for local files
                                                  : const AssetImage(
                                                        'lib/assets/doctor.png',
                                                      )
                                                      as ImageProvider,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['name'] ?? 'No Name',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                data['hospital'] ??
                                                    'No Hospital',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          backgroundColor:
                                              data['isAvailable'] == true
                                                  ? Colors.green[100]
                                                  : Colors.red[100],
                                          label: Text(
                                            data['isAvailable'] == true
                                                ? 'Available'
                                                : 'Unavailable',
                                            style: TextStyle(
                                              color:
                                                  data['isAvailable'] == true
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    // const SizedBox(height: 8),
                                    // Row(
                                    //   children: [
                                    //     Icon(
                                    //       Icons.phone,
                                    //       size: 16,
                                    //       color: Colors.blue,
                                    //     ),
                                    //     const SizedBox(width: 8),
                                    //     Text(data['phone'] ?? 'No Phone'),
                                    //   ],
                                    // ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(data['email'] ?? 'No Email'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          data['availableTime'] ??
                                              'No Time Specified',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          (data['availableDays']
                                                      as List<dynamic>? ??
                                                  [])
                                              .map(
                                                (day) => Chip(
                                                  label: Text(day.toString()),
                                                  backgroundColor:
                                                      Colors.blue[50],
                                                ),
                                              )
                                              .toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        Text(
                                          data['consultationFee'] != null
                                              ? 'Consultation Fee:'
                                              : 'No Fees Specified',
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          data['consultationFee'] != null
                                              ? 'BDT ${data['consultationFee']}'
                                              : 'No Fees Specified',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (data['appointmentLink'] != null &&
                                        data['appointmentLink'].isNotEmpty)
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Show confirmation dialog
                                          final confirmed = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    "Confirm Appointment",
                                                  ),
                                                  content: const Text(
                                                    "Are you sure you want to book this appointment?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        "Cancel",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        "Confirm",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirmed == true) {
                                            await _bookAppointment(data);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(130, 45),
                                        ),
                                        child: const Text('Book Appointment'),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Added: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment(Map<String, dynamic> doctorData) async {
    try {
      // String docId = '';
      // final snapshot =
      //     await FirebaseFirestore.instance.collection('doctors').get();
      // for (var doc in snapshot.docs) {
      //   docId = doc.id; // ✅ correct assignment
      // }
      final doctorDoc =
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(doctorData['doctorId'])
              .get();

      final existingAppointments =
          (doctorDoc.data()?['appointments'] as List<dynamic>? ?? [])
              .map((a) => (a['appointmentDate'] as Timestamp).toDate())
              .toList();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to book an appointment'),
          ),
        );
        return;
      }

      final timeRange = doctorData['availableTime'] as String;
      final timeParts = timeRange.split(' - ');
      if (timeParts.length != 2) throw Exception('Invalid time format');

      final startTime = _parseTimeString(timeParts[0]);
      final endTime = _parseTimeString(timeParts[1]);

      final now = DateTime.now();
      final initialMinute = now.minute ~/ 30 * 30;
      final initialDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        initialMinute,
      );

      TimeOfDay? pickedTime = TimeOfDay.fromDateTime(initialDateTime);

      final selectedTime = await showDialog<TimeOfDay>(
        context: context,
        builder: (context) {
          TimeOfDay? pickedTime = TimeOfDay.fromDateTime(
            initialDateTime,
          ); // Populate this with doctor's existing appointments

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select Appointment Time'),
                content: SizedBox(
                  height: 250,
                  child: Column(
                    children: [
                      const Text('Appointments must be 15 minutes apart'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          minuteInterval: 15,
                          initialDateTime: initialDateTime,
                          onDateTimeChanged: (DateTime date) {
                            setState(() {
                              pickedTime = TimeOfDay.fromDateTime(date);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (pickedTime == null) return;

                      final selectedTime = DateTime(
                        initialDateTime.year,
                        initialDateTime.month,
                        initialDateTime.day,
                        pickedTime!.hour,
                        pickedTime!.minute,
                      );

                      // Check 1: Within doctor's availability
                      final selectedMinutes =
                          pickedTime!.hour * 60 + pickedTime!.minute;
                      final startMinutes =
                          startTime.hour * 60 + startTime.minute;
                      final endMinutes = endTime.hour * 60 + endTime.minute;

                      if (selectedMinutes < startMinutes ||
                          selectedMinutes > endMinutes) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selected time is not within doctor\'s availability hours',
                            ),
                          ),
                        );
                        return;
                      }

                      // Check 2: At least 15 minutes after any existing appointment
                      for (final appointment in existingAppointments) {
                        final timeDiff =
                            selectedTime.difference(appointment).inMinutes;
                        if (timeDiff.abs() < 15) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please select a time at least 15 minutes after ${DateFormat('h:mm a').format(appointment)}',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      Navigator.pop(context, pickedTime);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (selectedTime == null) return;

      DateTime appointmentDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (appointmentDateTime.isBefore(now)) {
        appointmentDateTime = appointmentDateTime.add(const Duration(days: 1));
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('user_info')
              .doc(user.uid)
              .get();

      final appointmentData = {
        'uid': user.uid,
        'patientName': userDoc.data()?['name'] ?? 'Unknown',
        'doctorName': doctorData['name'],
        'speciality': doctorData ['specialty'],
        'paidAmount': doctorData['consultationFee'],
        'paid': true,
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'status': 'pending',
        'duration': 15,
        'createdAt': Timestamp.now(),
      };

         final batch = FirebaseFirestore.instance.batch();

    // 4. Update doctor's appointments
    final doctorRef = FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorData['doctorId']);
    
    batch.update(doctorRef, {
      'appointments': FieldValue.arrayUnion([appointmentData]),
      'updatedAt': Timestamp.now(),
    });

    // // 5. Create user appointment record
    // final userAppointmentRef = FirebaseFirestore.instance
    //     .collection('user_info')
    //     .doc(user.uid)
    //     .collection('appointments')
    //     .doc(); // Auto-generated ID
    
    // batch.set(userAppointmentRef, {
    //   ...appointmentData,
    //   'doctorData': {
    //     'name': doctorData['name'] ?? 'Unknown Doctor',
    //     'specialty': doctorData['specialty'] ?? 'General',
    //     'hospital': doctorData['hospital'] ?? '',
    //     'phone': doctorData['phone'] ?? '',
    //     'email': doctorData['email'] ?? '',
    //     'appointmentLink': doctorData['appointmentLink'] ?? '',
    //   },
    // });

    // 6. Commit the batch
    await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully!')),
      );

      if ((doctorData['appointmentLink'] ?? '').isNotEmpty) {
        _launchAppointmentLink(doctorData['appointmentLink']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final format = DateFormat('h:mm a');
    final dateTime = format.parse(timeStr);
    return TimeOfDay.fromDateTime(dateTime);
  }
}
