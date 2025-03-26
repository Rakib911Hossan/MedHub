import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditMedicine extends StatefulWidget {
  final String medicineId;
  const EditMedicine({super.key, required this.medicineId});

  @override
  _EditMedicineState createState() => _EditMedicineState();
}

class _EditMedicineState extends State<EditMedicine> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _genericGroupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicineDetails();
  }

  void _loadMedicineDetails() async {
    DocumentSnapshot medicine = await FirebaseFirestore.instance
        .collection('medicines')
        .doc(widget.medicineId)
        .get();

    if (medicine.exists) {
      setState(() {
        _nameController.text = medicine['name'] ?? '';
        _priceController.text = medicine['price'].toString();
        _imageController.text = medicine['image'] ?? '';
        _categoryController.text = medicine['category'] ?? '';
        _companyController.text = medicine['company'] ?? '';
        _genericGroupController.text = medicine['generic_group'] ?? '';
      });
    }
  }

  void _updateMedicine() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _genericGroupController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('medicines')
          .doc(widget.medicineId)
          .update({
        'name': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'image': _imageController.text,
        'category': _categoryController.text,
        'company': _companyController.text,
        'generic_group': _genericGroupController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating medicine: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                decoration: const InputDecoration(labelText: 'Image URL'),
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
                onPressed: _updateMedicine,
                child: const Text('Update Medicine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
