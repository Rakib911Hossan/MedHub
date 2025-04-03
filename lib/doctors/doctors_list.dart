import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorsList extends StatefulWidget {
  const DoctorsList({Key? key}) : super(key: key);

  @override
  _DoctorsListState createState() => _DoctorsListState();
}

class _DoctorsListState extends State<DoctorsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<DocumentSnapshot>> _groupedDoctors = {};

  Future<void> _launchAppointmentLink(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
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
    
    // Schedule the state update for the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _groupedDoctors = grouped;
        });
      }
    });
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
              const Color.fromARGB(255, 212, 231, 240)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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

            // Group doctors by specialty when new data arrives
            if (_groupedDoctors.isEmpty || 
                snapshot.data!.docs.length != _groupedDoctors.values.fold(0, (sum, list) => sum + list.length)) {
              _groupDoctorsBySpecialty(snapshot.data!.docs);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groupedDoctors.length,
              itemBuilder: (context, index) {
                final specialty = _groupedDoctors.keys.elementAt(index);
                final doctors = _groupedDoctors[specialty]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: data['profileImage'] != null && data['profileImage'].isNotEmpty
                                        ? NetworkImage(data['profileImage'])
                                        : const AssetImage('lib/assets/order_medicine.jpg') as ImageProvider,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          data['hospital'] ?? 'No Hospital',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    backgroundColor: data['isAvailable'] == true 
                                        ? Colors.green[100] 
                                        : Colors.red[100],
                                    label: Text(
                                      data['isAvailable'] == true ? 'Available' : 'Unavailable',
                                      style: TextStyle(
                                        color: data['isAvailable'] == true 
                                            ? Colors.green 
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(data['phone'] ?? 'No Phone'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(data['email'] ?? 'No Email'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(data['availableTime'] ?? 'No Time Specified'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: (data['availableDays'] as List<dynamic>? ?? [])
                                    .map((day) => Chip(
                                          label: Text(day.toString()),
                                          backgroundColor: Colors.blue[50],
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              if (data['appointmentLink'] != null && data['appointmentLink'].isNotEmpty)
                                ElevatedButton(
                                  onPressed: () => _launchAppointmentLink(data['appointmentLink']),
                                  child: const Text('Book Appointment'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 40),
                                  ),
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
                    }).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';

// class DoctorsList extends StatefulWidget {
//   const DoctorsList({Key? key}) : super(key: key);

//   @override
//   _DoctorsListState createState() => _DoctorsListState();
// }

// class _DoctorsListState extends State<DoctorsList> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, List<DocumentSnapshot>> _groupedDoctors = {};
//   Set<String> _expandedSpecialties = Set();

//   Future<void> _launchAppointmentLink(String url) async {
//     if (url.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No appointment link available')),
//       );
//       return;
//     }
    
//     try {
//       if (await canLaunchUrl(Uri.parse(url))) {
//         await launchUrl(Uri.parse(url));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not launch $url')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error launching URL: $e')),
//       );
//     }
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     return DateFormat('MMMM d, y - h:mm a').format(timestamp.toDate());
//   }

//   void _groupDoctorsBySpecialty(List<DocumentSnapshot> doctors) {
//     final grouped = <String, List<DocumentSnapshot>>{};
    
//     for (var doctor in doctors) {
//       final data = doctor.data() as Map<String, dynamic>;
//       final specialty = data['specialty'] ?? 'Other';
      
//       if (!grouped.containsKey(specialty)) {
//         grouped[specialty] = [];
//       }
//       grouped[specialty]!.add(doctor);
//     }
    
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         setState(() {
//           _groupedDoctors = grouped;
//         });
//       }
//     });
//   }

//   void _toggleSpecialtyExpansion(String specialty) {
//     setState(() {
//       if (_expandedSpecialties.contains(specialty)) {
//         _expandedSpecialties.remove(specialty);
//       } else {
//         _expandedSpecialties.add(specialty);
//       }
//     });
//   }

//   Widget _buildDoctorImage(String? imageUrl) {
//     if (imageUrl == null || imageUrl.isEmpty) {
//       return Image.asset('lib/assets/order_medicine.jpg', fit: BoxFit.cover);
//     }
    
//     // Check if it's a local file path or network URL
//     if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
//       return Image.network(
//         imageUrl,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => _buildFallbackImage(),
//       );
//     } else {
//       // Handle local file paths
//       try {
//         return Image.file(
//           File(imageUrl),
//           fit: BoxFit.cover,
//           errorBuilder: (_, __, ___) => _buildFallbackImage(),
//         );
//       } catch (e) {
//         return _buildFallbackImage();
//       }
//     }
//   }

//   Widget _buildFallbackImage() {
//     return Image.asset('lib/assets/order_medicine.jpg', fit: BoxFit.cover);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctors List'),
//         backgroundColor: Colors.blueGrey,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               const Color.fromARGB(255, 225, 231, 243),
//               const Color.fromARGB(255, 212, 231, 240)
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore.collection('doctors').snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.data!.docs.isEmpty) {
//               return const Center(child: Text('No doctors found'));
//             }

//             if (_groupedDoctors.isEmpty || 
//                 snapshot.data!.docs.length != _groupedDoctors.values.fold(0, (sum, list) => sum + list.length)) {
//               _groupDoctorsBySpecialty(snapshot.data!.docs);
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _groupedDoctors.length,
//               itemBuilder: (context, index) {
//                 final specialty = _groupedDoctors.keys.elementAt(index);
//                 final doctors = _groupedDoctors[specialty]!;
//                 final isExpanded = _expandedSpecialties.contains(specialty);

//                 return Card(
//                   elevation: 4,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: InkWell(
//                     onTap: () => _toggleSpecialtyExpansion(specialty),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   specialty,
//                                   style: const TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blueGrey,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               Icon(
//                                 isExpanded ? Icons.expand_less : Icons.expand_more,
//                                 color: Colors.blueGrey,
//                               ),
//                             ],
//                           ),
//                           if (isExpanded) ...[
//                             const SizedBox(height: 16),
//                             ...doctors.map((doctor) {
//                               var data = doctor.data() as Map<String, dynamic>;
                              
//                               return Column(
//                                 children: [
//                                   const Divider(),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius: BorderRadius.circular(8),
//                                         child: Container(
//                                           width: 80,
//                                           height: 80,
//                                           child: _buildDoctorImage(data['profileImage']),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               data['name'] ?? 'No Name',
//                                               style: const TextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               data['hospital'] ?? 'No Hospital',
//                                               style: TextStyle(
//                                                 fontSize: 14,
//                                                 color: Colors.grey[600],
//                                               ),
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Row(
//                                               children: [
//                                                 Icon(Icons.phone, size: 16, color: Colors.blue),
//                                                 const SizedBox(width: 8),
//                                                 Expanded(
//                                                   child: Text(
//                                                     data['phone'] ?? 'No Phone',
//                                                     overflow: TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Row(
//                                               children: [
//                                                 Icon(Icons.access_time, size: 16, color: Colors.blue),
//                                                 const SizedBox(width: 8),
//                                                 Expanded(
//                                                   child: Text(
//                                                     data['availableTime'] ?? 'No Time Specified',
//                                                     overflow: TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       Chip(
//                                         backgroundColor: data['isAvailable'] == true 
//                                             ? Colors.green[100] 
//                                             : Colors.red[100],
//                                         label: Text(
//                                           data['isAvailable'] == true ? 'Available' : 'Unavailable',
//                                           style: TextStyle(
//                                             color: data['isAvailable'] == true 
//                                                 ? Colors.green 
//                                                 : Colors.red,
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Wrap(
//                                     spacing: 8,
//                                     children: (data['availableDays'] as List<dynamic>? ?? [])
//                                         .map((day) => Chip(
//                                               label: Text(day.toString()),
//                                               backgroundColor: Colors.blue[50],
//                                             ))
//                                         .toList(),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   if (data['appointmentLink'] != null && data['appointmentLink'].isNotEmpty)
//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: ElevatedButton(
//                                         onPressed: () => _launchAppointmentLink(data['appointmentLink']),
//                                         child: const Text('Book Appointment'),
//                                       ),
//                                     ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     'Added: ${_formatTimestamp(data['createdAt'] as Timestamp)}',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                       fontStyle: FontStyle.italic,
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             }).toList(),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }