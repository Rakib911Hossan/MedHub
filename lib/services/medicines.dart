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

          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              var medicine = medicines[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.medical_services, color: Colors.blue),
                  title: Text(medicine['name'] ?? 'Unknown Medicine'),
                  subtitle: Text("Price: \$${medicine['price'] ?? 'N/A'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMedicine(medicineId: medicine.id),
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
                ),
              );
            },
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
