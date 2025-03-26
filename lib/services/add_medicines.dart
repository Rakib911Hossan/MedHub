import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMedicine extends StatefulWidget {
  const AddMedicine({super.key});

  @override
  _AddMedicineState createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _genericGroupController = TextEditingController();

  final CollectionReference medicinesCollection = FirebaseFirestore.instance
      .collection('medicines');

  Future<void> _addMedicine() async {
    String name = _nameController.text.trim();
    String price = _priceController.text.trim();
    String image = _imageController.text.trim();
    String category = _categoryController.text.trim();
    String company = _companyController.text.trim();
    String genericGroup = _genericGroupController.text.trim();
    String? uid =
        FirebaseAuth.instance.currentUser?.uid; // Get logged-in user ID

    if (name.isEmpty ||
        price.isEmpty ||
        category.isEmpty ||
        company.isEmpty ||
        genericGroup.isEmpty ||
        uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required!')));
      return;
    }

    try {
      await medicinesCollection.add({
        'uid': uid, // User ID
        'name': name,
        'price': double.tryParse(price) ?? 0.0,
        'image':
            image.isNotEmpty
                ? image
                : "https://via.placeholder.com/150", // Default placeholder if no image
        'category': category,
        'company': company,
        'generic_group': genericGroup,
        'timestamp': FieldValue.serverTimestamp(), // Firestore timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully!')),
      );

      Navigator.pop(context); // Go back after adding medicine
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding medicine: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
              ),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            TextField(
              controller: _genericGroupController,
              decoration: const InputDecoration(labelText: 'Generic Group'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addMedicine,
              child: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }
}
