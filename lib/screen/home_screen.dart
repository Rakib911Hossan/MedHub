import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:new_project/doctors/edit_doctors_profile.dart';
import 'package:new_project/order/all_orders.dart';
import 'package:new_project/order/order_medicine.dart';
import 'package:new_project/medicine/medicines.dart';
import 'package:new_project/order/orders.dart';
import 'package:new_project/reminder/reminder.dart';
import 'package:new_project/users/profile_screen.dart';
import 'package:new_project/users/user_list';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userRole = 'user';
  String userName = 'User';
  String userId = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }



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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(
                        255,
                        26,
                        67,
                        114,
                      ), // Header background color
                    ),
                    accountName: Text(
                      userName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    accountEmail: Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blueAccent),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.blueGrey),
                    title: const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.black87,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    tileColor: Colors.grey[100],
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.black87,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    tileColor: Colors.grey[100],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: Colors.indigo,
                    ),
                    title: const Text(
                      'Orders',
                      style: TextStyle(
                        color: Colors.black87,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Orders()),
                      );
                    },
                  ),
                  // ListTile(
                  //   leading: const Icon(
                  //     Icons
                  //         .calendar_today, // Or Icons.event_available for alternate icon
                  //     color: Colors.indigo, // Matching your orders tile color
                  //   ),
                  //   title: const Text(
                  //     'Appointments',
                  //     style: TextStyle(color: Colors.black87),
                  //   ),
                  //   tileColor: Colors.grey[100],
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(10),
                  //   ),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const AppointmentsScreen(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  if (userRole == 'admin' || userRole == 'deliveryMan')
                    ListTile(
                      leading: const Icon(
                        Icons.receipt_rounded,
                        color: Color.fromARGB(255, 5, 26, 148),
                      ),
                      title: const Text(
                        'All Orders',
                        style: TextStyle(
                          color: Colors.black87,
                          // fontWeight: FontWeight.w600,
                        ),
                      ),
                      tileColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllOrders(),
                          ),
                        );
                      },
                    ),
                  if (userRole == 'admin')
                    ListTile(
                      leading: const Icon(
                        Icons.medication,
                        color: Color.fromARGB(255, 219, 46, 46),
                      ),
                      title: const Text(
                        'Medicines',
                        style: TextStyle(
                          color: Colors.black87,
                          // fontWeight: FontWeight.w600,
                        ),
                      ),
                      tileColor: Colors.grey[100],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Medicines(),
                          ),
                        );
                      },
                    ),
                  // if (userRole == 'doctor' || userRole == 'admin')
                  //   ListTile(
                  //     leading: const Icon(
                  //       Icons.medical_services,
                  //       color: Color.fromARGB(255, 46, 125, 219),
                  //     ),
                  //     title: const Text(
                  //       'Doctors Profiles',
                  //       style: TextStyle(color: Colors.black87),
                  //     ),
                  //     tileColor: Colors.grey[100],
                  //     onTap: () async {
                  //       bool hasProfile = await _fetchExistingProfile();

                  //       if (!hasProfile) {
                  //         // If no profile exists, navigate to AddDoctorsProfile
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (context) => const AddDoctorsProfile(),
                  //           ),
                  //         );
                  //       }
                  //     },
                  //   ),

                  if (userRole == 'admin')
                    ListTile(
                      leading: const Icon(
                        Icons.account_circle,
                        color: Colors.deepPurple,
                      ),
                      title: const Text(
                        'Users',
                        style: TextStyle(
                          color: Colors.black87,
                          // fontWeight: FontWeight.w600,
                        ),
                      ),
                      tileColor: Colors.grey[100],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Users(),
                          ),
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_outlined,
                      color: Color.fromARGB(255, 136, 12, 3),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.black87,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    tileColor: Colors.grey[100],
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Exit option at the bottom
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Exit'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  SystemNavigator.pop(); // Close the app completely
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $userName",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We are here to help you connect with your doctor and get your medicines",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Column(
                children: [
                  _buildServiceCard(
                    context,
                    'lib/assets/medicine.png',
                    'Order Medicine',
                    'Get your medicines delivered to your door',
                    const Color.fromARGB(255, 226, 189, 178), // Light pink
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderMedicine(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildServiceCard(
                    context,
                    'lib/assets/doctor.jpg',
                    'Consult Doctor',
                    'Get expert medical advice from your home',
                    const Color.fromARGB(255, 93, 166, 238), () {}, // Azure blue
                    // () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => const DoctorsList(),
                    //     ),
                    //   );
                    // },
                  ),
                  const SizedBox(height: 15),
                  _buildServiceCard(
                    context,
                    'lib/assets/time.png', // Use a medicine/reminder related image
                    'Medicine Reminder',
                    'Never miss a dose',
                    const Color.fromARGB(255, 106, 179, 129),  // Fresh green (like pills/health)
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const MedicineReminder(), // Your reminder screen
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String imagePath,
    String title,
    String description,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    // Determine text color based on background brightness
    final bool isLightBackground = backgroundColor.computeLuminance() > 0.5;
    final Color textColor = isLightBackground ? Colors.black87 : Colors.white;
    final Color secondaryTextColor =
        isLightBackground ? Colors.black54 : Colors.white70;

    return Card(
      elevation: 4,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(
                    isLightBackground ? 0.1 : 0.3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.medication, size: 40, color: textColor);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _fetchExistingProfile() async {
    if (userId.isEmpty) {
      debugPrint('Error: userId is empty.');
      return false;
    }

    try {
      var existingProfile =
          await FirebaseFirestore.instance
              .collection('doctors')
              .where('doctorId', isEqualTo: userId)
              .get();

      debugPrint('Fetched profile count: ${existingProfile.docs.length}');

      if (existingProfile.docs.isNotEmpty) {
        debugPrint(
          'Doctor Profile Found: ${existingProfile.docs.first.data()}',
        );

        // Navigate to edit screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EditDoctorProfile(
                    doctorId: existingProfile.docs.first.id,
                    existingData: existingProfile.docs.first.data(),
                  ),
            ),
          );
        });

        return true; // Profile exists
      } else {
        debugPrint('No existing profile found for userId: $userId');
        return false; // Profile does not exist
      }
    } catch (e) {
      debugPrint('Error fetching doctor profile: $e');
      return false;
    }
  }
}
