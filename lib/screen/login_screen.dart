import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_project/reminder/notification.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'reset_password_screen.dart';
 // Import the NotificationService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  bool _validateInputs() {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (emailController.text.trim().isEmpty) {
      setState(() => emailError = 'Please enter your email');
      return false;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(emailController.text.trim())) {
      setState(() => emailError = 'Please enter a valid email address');
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      setState(() => passwordError = 'Please enter your password');
      return false;
    } else if (passwordController.text.length < 6) {
      setState(() => passwordError = 'Password must be at least 6 characters');
      return false;
    }

    return true;
  }

  void _login() async {
  if (!_validateInputs()) return;

  try {
    // Sign in with email and password
    await _auth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Initialize notifications after successful login
    await NotificationService().init();

    // Fetch the user's medicine reminders from Firestore
    String userId = _auth.currentUser!.uid;

    // Get the first reminder from Firestore for this user
    final remindersSnapshot = await FirebaseFirestore.instance
        .collection('user_info')
        .doc(userId)
        .collection('medicine_reminders')
        .get();

    if (remindersSnapshot.docs.isEmpty) {
      debugPrint('No reminders found for the user');
      return;
    }

    // Fetch the first reminder ID (or modify this to select based on a specific criteria)
    List<String> reminderIds = remindersSnapshot.docs.map((doc) => doc.id).toList();

    // Schedule notifications for all reminders
    for (String reminderId in reminderIds) {
      await NotificationService().scheduleNotificationFromFirestore(userId, reminderId);
    }

    // Show a success message and navigate to the home screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login Successful")),
    );
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } on FirebaseAuthException catch (e) {
    setState(() {
      if (e.code == 'user-not-found') {
        emailError = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        passwordError = 'Wrong password. Try again';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An unexpected error occurred')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                errorText: emailError,
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                errorText: passwordError,
              ),
            ),
            const SizedBox(height: 10.0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              ),
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
