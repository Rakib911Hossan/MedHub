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
  final CollectionReference medicinesCollection =
      FirebaseFirestore.instance.collection('medicines');

  void _deleteMedicine(String id) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this medicine?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        title: const Text('Medicines'),
      ),
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

          return ListView(
            children: categorizedMedicines.keys.map((category) {
              return ExpansionTile(
                // The title will be the category name
                title: Text(
                  category,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // The children will be all the medicines under this category, shown row-wise with horizontal scroll
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Horizontal scrolling
                    child: Row(
                      children: categorizedMedicines[category]!.map<Widget>((medicine) {
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Column(
                            children: [
                              const Icon(Icons.medical_services, color: Colors.blue),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  medicine['name'] ?? 'Unknown Medicine',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Text("Price: \$${medicine['price'] ?? 'N/A'}"),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.green),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditMedicine(medicineId: medicine.id),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteMedicine(medicine.id),
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
