import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddMedicine extends StatefulWidget {
  const AddMedicine({super.key});

  @override
  _AddMedicineState createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _genericGroupController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  double _totalPrice = 0.0;
  double _discountAmountEach = 0.0;
  double _discountedPriceEach = 0.0;
  double _totalDiscountAmount = 0.0;
  double _totalDiscountedPrice = 0.0;

  final CollectionReference medicinesCollection = FirebaseFirestore.instance
      .collection('medicines');

  void _calculateTotalPrice() {
    double price = double.tryParse(_priceController.text) ?? 0.0;
    int quantity = int.tryParse(_quantityController.text) ?? 0;
    double discountPercent = double.tryParse(_discountPercentController.text) ?? 0.0;
    setState(() {
      _totalPrice = price * quantity;
       _discountAmountEach =  (price * discountPercent) / 100;
      _discountedPriceEach = price - _discountAmountEach;
      _totalDiscountAmount = (_totalPrice * discountPercent) / 100;
      _totalDiscountedPrice = _totalPrice - _totalDiscountAmount;
    });
  }

  Future<void> _addMedicine() async {
    String name = _nameController.text.trim();
    String price = _priceController.text.trim();
    String quantity = _quantityController.text.trim();
    String discountPercent = _discountPercentController.text.trim();
    String image = _imageController.text.trim();
    String category = _categoryController.text.trim();
    String company = _companyController.text.trim();
    String genericGroup = _genericGroupController.text.trim();
    String description = _descriptionController.text.trim();
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (name.isEmpty ||
        price.isEmpty ||
        quantity.isEmpty ||
        discountPercent.isEmpty ||
        category.isEmpty ||
        company.isEmpty ||
        description.isEmpty ||
        genericGroup.isEmpty ||
        uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required!')));
      return;
    }

    try {
      await medicinesCollection.add({
        'uid': uid,
        'name': name,
        'price': double.tryParse(price) ?? 0.0,
        'quantity': int.tryParse(quantity) ?? 0,
        'discount_percent': double.tryParse(discountPercent) ?? 0.0,
        'discount_amount': _discountAmountEach,
        'discount_price_each': _discountedPriceEach,
        'total_discount_amount': _totalDiscountAmount,
        'total_discount_price': _totalDiscountedPrice,
        'total_price': _totalPrice,
        'image': image.isNotEmpty ? image : "https://via.placeholder.com/150",
        'category': category,
        'company': company,
        'generic_group': genericGroup,
        'description': description,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully!')),
      );

      Navigator.pop(context);
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
                                    errorBuilder: (context, error, stackTrace) {
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
                          color: const Color.fromARGB(255, 14, 138, 111),
                        ),
                        onPressed: _selectImage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price for each medicine',
              ),
              onChanged: (value) => _calculateTotalPrice(),
            ),
            TextField(
              controller: _discountPercentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount Percentage',
              ),
              onChanged: (value) => _calculateTotalPrice(),
            ),
            TextField(
              controller: TextEditingController(text: _discountAmountEach.toString()),
              enabled: false, // Disable editing
              decoration: const InputDecoration(
                labelText: 'Discount Amount Each (auto-calculated)',
              ),
            ),
            TextField(
              controller: TextEditingController(text: _discountedPriceEach.toString()),
              enabled: false, // Disable editing
              decoration: const InputDecoration(
                labelText: 'Discounted Price Each (auto-calculated)',
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
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity of medicine',
              ),
              onChanged: (value) => _calculateTotalPrice(),
            ),
            TextField(
              controller: TextEditingController(text: _totalPrice.toString()),
              enabled: false, // Disable editing
              decoration: const InputDecoration(
                labelText: 'Total Price (auto-calculated)',
              ),
            ),
            TextField(
              controller: TextEditingController(text: _totalDiscountedPrice.toString()),
              enabled: false, // Disable editing
              decoration: const InputDecoration(
                labelText: 'Total Discounted Price (auto-calculated)',
              ),
            ),
            TextField(
              controller: TextEditingController(text: _totalDiscountAmount.toString()),
              enabled: false, // Disable editing
              decoration: const InputDecoration(
                labelText: 'Total Discount Amount (auto-calculated)',
              ),
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
