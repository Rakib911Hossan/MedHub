import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryAddressPage extends StatefulWidget {
  final User user;
  final String initialAddress;
  final String initialPhone;

  const DeliveryAddressPage({
    super.key,
    required this.user,
    required this.initialAddress,
    required this.initialPhone,
  });

  @override
  _DeliveryAddressPageState createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateUserDetails() async {
  final newAddress = _addressController.text.trim();
  final newPhone = _phoneController.text.trim();

  // Basic validation
  if (newAddress.isEmpty || newPhone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Update ONLY address and phone fields
    await FirebaseFirestore.instance
        .collection('user_info')
        .doc(widget.user.uid)
        .update({
          'address': newAddress,
          'phone': int.parse(newPhone), // Convert to number to match your schema
          'updatedAt': FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address and phone updated successfully')),
    );
    
    Navigator.pop(context, {
      'address': newAddress,
      'phone': newPhone,
    });

  } on FormatException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone must contain only numbers')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update failed: ${e.toString()}')),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Delivery Details'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateUserDetails,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Enter your complete address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}