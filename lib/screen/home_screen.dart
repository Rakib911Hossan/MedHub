import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome, ${user?.email ?? 'Guest'}"),
              const SizedBox(height: 20),
              // First widget for ordering medicine
              GestureDetector(
                onTap: () {
                  // Navigate to the order medicine screen (You can create this screen)
                },
                child: Card(
                  elevation: 5.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('lib/assets/order_medicine.jpg', height: 100, width: 100),
                      const SizedBox(height: 10),
                      const Text('Order Medicine', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Second widget for consulting doctor
              GestureDetector(
                onTap: () {
                  // Navigate to the consult doctor screen (You can create this screen)
                },
                child: Card(
                  elevation: 5.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('lib/assets/doctor.jpg', height: 100, width: 100),
                      const SizedBox(height: 10),
                      const Text('Consult Doctor', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
