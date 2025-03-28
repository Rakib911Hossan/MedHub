import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditMedicine extends StatefulWidget {
  final String medicineId;
  const EditMedicine({super.key, required this.medicineId});

  @override
  _EditMedicineState createState() => _EditMedicineState();
}

class _EditMedicineState extends State<EditMedicine> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _genericGroupController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicineDetails();
  }

  Future<void> _loadMedicineDetails() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot medicine =
          await FirebaseFirestore.instance
              .collection('medicines')
              .doc(widget.medicineId)
              .get();

      if (medicine.exists) {
        setState(() {
          _nameController.text = medicine['name'] ?? '';
          _priceController.text = medicine['price'].toString();
          _quantityController.text = medicine['quantity'].toString();
          _totalPriceController.text = medicine['total_price'].toString();
          _imageController.text = medicine['image'] ?? '';
          _categoryController.text = medicine['category'] ?? '';
          _companyController.text = medicine['company'] ?? '';
          _genericGroupController.text = medicine['generic_group'] ?? '';
        });
        _calculateTotalPrice();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading medicine details: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  void _calculateTotalPrice() {
    double price = double.tryParse(_priceController.text) ?? 0.0;
    int quantity = int.tryParse(_quantityController.text) ?? 1;
    setState(() {
      _totalPriceController.text = (price * quantity).toString();
    });
  }

  Future<void> _updateMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('medicines')
          .doc(widget.medicineId)
          .update({
            'name': _nameController.text,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'quantity': int.tryParse(_quantityController.text) ?? 1,
            'total_price': double.tryParse(_totalPriceController.text) ?? 0.0,
            'image': _imageController.text,
            'category': _categoryController.text,
            'company': _companyController.text,
            'generic_group': _genericGroupController.text,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Delay dialog to ensure the context is fully available
      Future.delayed(const Duration(milliseconds: 200), () {
        _showUpdateDialog(); // Show the update dialog
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine updated successfully!')),
      );
      Navigator.pop(context); // Close the current screen after the update
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating medicine: $e')));
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Medicine Updated'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${_nameController.text}'),
              Text('Category: ${_categoryController.text}'),
              Text('Company: ${_companyController.text}'),
              Text('Generic Group: ${_genericGroupController.text}'),
              Text(
                'Price: ${_priceController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Quantity: ${_quantityController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Total Price: ${_totalPriceController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Medicine')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment:
                                    Alignment
                                        .bottomRight, // Position the icon at the bottom-right
                                children: [
                                  // Container for the image with border radius
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), // Adjust the radius as needed
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(
                                          0.3,
                                        ), // Optional border color
                                        width: 1, // Optional border width
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), // Same radius as container
                                      child:
                                          _imageController.text.isNotEmpty
                                              ? Image.file(
                                                File(_imageController.text),
                                                height: 150,
                                                width: 150,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Image.asset(
                                                    'lib/assets/order_medicine.jpg',
                                                    height: 150,
                                                    width: 150,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              )
                                              : Image.asset(
                                                'lib/assets/order_medicine.jpg',
                                                height: 150,
                                                width: 150,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ), // Added spacing between image and button
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: const Color.fromARGB(
                                        255,
                                        14,
                                        138,
                                        111,
                                      ),
                                    ),
                                    onPressed: _selectImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Required field' : null,
                        ),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price'),
                          onChanged: (_) => _calculateTotalPrice(),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Required field' : null,
                        ),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                          onChanged: (_) => _calculateTotalPrice(),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Required field' : null,
                        ),
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Required field' : null,
                        ),
                        TextFormField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Required field' : null,
                        ),
                        TextFormField(
                          controller: _genericGroupController,
                          decoration: const InputDecoration(
                            labelText: 'Generic Group',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Required field' : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Price: ${_totalPriceController.text}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateMedicine,
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageController.text =
            pickedFile.path; // Store the file path in the controller
      });
    } else {
      print('No image selected');
    }
  }
}
