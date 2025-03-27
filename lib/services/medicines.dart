import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_project/services/add_medicines.dart';
import 'package:new_project/services/edit_medicine.dart';

class Medicines extends StatefulWidget {
  const Medicines({super.key});

  @override
  _MedicinesState createState() => _MedicinesState();
}

class _MedicinesState extends State<Medicines> {
  final CollectionReference medicinesCollection = FirebaseFirestore.instance
      .collection('medicines');

  void _deleteMedicine(String id) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this medicine?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmDelete == true) {
      await medicinesCollection.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicine deleted successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      body: StreamBuilder<QuerySnapshot>(
        stream: medicinesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No medicines available.'));
          }

          var medicines = snapshot.data!.docs;

          // ✅ Group medicines by category
          Map<String, List<DocumentSnapshot>> categorizedMedicines = {};
          for (var med in medicines) {
            String category = med['category'] ?? 'Uncategorized';
            if (!categorizedMedicines.containsKey(category)) {
              categorizedMedicines[category] = [];
            }
            categorizedMedicines[category]!.add(med);
          }
          // Store random colors for each medicine
          final Map<String, Color> medicineColors = {};

          Color getRandomColor(String medicineId) {
            if (!medicineColors.containsKey(medicineId)) {
              final Random random = Random();

              // Determine the index for alternating colors
              int index =
                  medicineColors
                      .length; // Use the number of colors already assigned
              bool isAzure =
                  index % 2 ==
                  0; // If index is even, it's Azure, else it's Mint

              medicineColors[medicineId] = Color.fromRGBO(
                isAzure ? 240 : 189, // Azure if even index, Mint if odd
                isAzure
                    ? 255 : 255, // Both Azure and Mint have similar greenish component
                isAzure ? 255 : 203, // Azure if even index, Mint if odd
                0.8, // 80% opacity
              );
            }
            return medicineColors[medicineId]!; // Return stored color
          }

          return ListView(
            children:
                categorizedMedicines.keys.map((category) {
                  return ExpansionTile(
                    // The title will be the category name
                    title: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // The children will be all the medicines under this category, shown row-wise with horizontal scroll
                    children: [
                      SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal, // Horizontal scrolling
                        child: Row(
                          children:
                              categorizedMedicines[category]!.map<Widget>((
                                medicine,
                              ) {
                                return Card(
                                  elevation: 3,
                                  color: getRandomColor(medicine.id),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      // Medicine Image (Load from local storage or fallback to default)
                                      Container(
                                        height: 80, // Small size for the image
                                        width: 80,

                                        child:
                                            medicine['image'] != null &&
                                                    medicine['image'].isNotEmpty
                                                ? Image.file(
                                                  File(
                                                    medicine['image'],
                                                  ), // Load from local storage
                                                  height: 80,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Image.asset(
                                                      'lib/assets/order_medicine.jpg', // Default fallback image
                                                      height: 80,
                                                      width: 100,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                                : Image.asset(
                                                  'lib/assets/order_medicine.jpg', // Default fallback image
                                                  height: 80,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                      // const Icon(Icons.medical_services, color: Colors.blue),
                                      Padding(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Text(
                                          medicine['name'] ??
                                              'Unknown Medicine',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Text(
                                        "   Price: BDT ${medicine['price'] ?? 'N/A'}   ",
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color.fromARGB(255, 3, 73, 5),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => EditMedicine(
                                                        medicineId: medicine.id,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Color.fromARGB(255, 221, 128, 121),
                                            ),
                                            onPressed:
                                                () => _deleteMedicine(
                                                  medicine.id,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicine()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
