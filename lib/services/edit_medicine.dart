import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating medicine: $e')));
    }
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
                              _imageController.text.isNotEmpty
                                  ? Image.network(
                                    _imageController.text,
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
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _imageController,
                                decoration: const InputDecoration(
                                  labelText: 'Image URL',
                                ),
                                onChanged: (value) {
                                  setState(
                                    () {},
                                  ); // Forces UI update when URL changes
                                },
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
}
