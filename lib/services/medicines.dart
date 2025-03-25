import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Medicines extends StatefulWidget {
  const Medicines({super.key});

  @override
  _MedicinesState createState() => _MedicinesState();
}

class _MedicinesState extends State<Medicines> {
  final CollectionReference medicinesCollection =
      FirebaseFirestore.instance.collection('medicines');

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

          // Convert Firestore documents to a list of medicines
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
                  trailing: Text(
                    medicine['category'] ?? 'Unknown Category',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
