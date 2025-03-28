import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:new_project/order/order_medicine.dart';
import 'package:new_project/services/medicines.dart';
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
                    accountName: Text(userName),
                    accountEmail: Text(user?.email ?? ''),
                    currentAccountPicture: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  if (userRole == 'admin')
                    ListTile(
                      leading: const Icon(Icons.medication),
                      title: const Text('Medicines'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Medicines(),
                          ),
                        );
                      },
                    ),
                  if (userRole == 'admin')
                    ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: const Text('Users'),
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
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('Logout'),
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
                        fontSize: 16,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                  const SizedBox(height: 20),
                  _buildServiceCard(
                    context,
                    'lib/assets/doctor.jpg',
                    'Consult Doctor',
                    'Get expert medical advice from your home',
                    const Color.fromARGB(255, 93, 166, 238), // Azure blue
                    () {
                      // Navigation for consult doctor
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
}
