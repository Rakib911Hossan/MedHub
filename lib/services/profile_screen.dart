import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_project/services/edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // Initialize the user and fetch data
  Future<void> _initializeUser() async {
    // Fetch the current user and reload to get up-to-date info
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser
          .reload(); // Reload the current user to ensure up-to-date data
      setState(() {
        user = currentUser;
      });
      _fetchUserData();
    } else {
      setState(() {
        _isLoading = false; // Stop loading if no user is logged in
      });
    }
  }

  // Fetch user data from Firestore by UID
  Future<void> _fetchUserData() async {
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('user_info')
              .doc(user!.uid) // Fetch document by UID
              .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>?;
        });
      } else {
        // Handle case where the document does not exist
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User data not found")));
      }
    } catch (e) {
      // Handle error while fetching data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch user data")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide the loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Loading indicator
              : userData == null
              ? const Center(child: Text('No user data available'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Display user icon as the first letter of email
                      CircleAvatar(
                        radius: 50,
                        child: Text(
                          userData?['email']?.substring(0, 1).toUpperCase() ??
                              'N', // First letter of email
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor:
                            Colors
                                .blueAccent, // You can customize the background color
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData?['name'] ?? 'Name not available',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userData?['phone'] != null
                            ? '0${userData?['phone'].toString()}'
                            : 'Phone not available',
                        style: const TextStyle(fontSize: 18),
                      ),

                      const SizedBox(height: 20),
                      // Display other fields below
                      _buildUserInfoRow(
                        "Email",
                        userData?['email'] ?? 'Not available',
                      ),
                      _buildUserInfoRow(
                        "Age",
                        userData?['age']?.toString() ?? 'Not available',
                      ),
                      _buildUserInfoRow(
                        "Gender",
                        userData?['gender'] ?? 'Not available',
                      ),
                      _buildUserInfoRow(
                        "Address",
                        userData?['address'] ?? 'Not available',
                      ),
                      // _buildUserInfoRow("Role", userData?['role'] ?? 'Not available'),
                      const SizedBox(height: 20),
                      // Edit button - Navigate to EditProfileScreen
                      ElevatedButton(
                        onPressed: () async {
                          // Wait for the EditProfileScreen to return and refresh the data
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditProfileScreen(
                                    userData: userData!,
                                  ), // Pass userData to EditProfileScreen
                            ),
                          );
                          _fetchUserData(); // Reload data after the edit
                        },
                        child: const Text('Edit User'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Widget to display user info rows
  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
