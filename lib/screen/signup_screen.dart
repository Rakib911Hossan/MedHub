import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  // Form validation logic
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  bool _validateInputs() {
    setState(() {
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    if (confirmPasswordController.text.trim().isEmpty) {
      setState(() => confirmPasswordError = 'Please confirm your password');
      return false;
    } else if (passwordController.text != confirmPasswordController.text) {
      setState(() => confirmPasswordError = 'Passwords do not match');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      setState(() => emailError = 'Please enter your email');
      return false;
    } else if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(emailController.text.trim())) {
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

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pop(context); // Navigate back to login screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Sign up logic with Firebase
  void _signUp() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Get the user UID
      String uid = userCredential.user!.uid;

      // Add user data to Firestore
      await _firestore.collection('user_info').doc(uid).set({
        'uid': uid,
        'email': emailController.text.trim(),
        'name': '', // You can add a name field here if needed
        'phone': 0, // You can add a phone field here if needed
        'age': 0, // You can add an age field here if needed
        'gender': '', // You can add a gender field here if needed
        'address': '', // You can add an address field here if needed
        'role': 'user', // Default role, can be modified later
      });

      // Show success dialog
      _showSuccessDialog("Account created successfully! You can now log in.");
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog("An unexpected error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Firebase Error Message Handler
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already in use. Please try logging in.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger one.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
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
            const SizedBox(height: 20.0),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                errorText: confirmPasswordError,
              ),
            ),
            const SizedBox(height: 30.0),
            _isLoading
                ? const CircularProgressIndicator() // Show loading indicator
                : ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Sign Up'),
                ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Log In'),
            ),
          ],
        ),
      ),
    );
  }
}
