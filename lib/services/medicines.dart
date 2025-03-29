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
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.4),
            hintText: 'Search medicines...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          suffixIcon:
                searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchQuery = '');
                        FocusScope.of(context).unfocus();
                      },
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged:
              (value) => setState(() => searchQuery = value.toLowerCase()),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(DocumentSnapshot medicine) {
    final Map<String, Color> medicineColors = {};

    Color getRandomColor(String medicineId) {
      if (!medicineColors.containsKey(medicineId)) {
        final Random random = Random();

        // Generate random pastel colors by mixing with white
        medicineColors[medicineId] = Color.fromRGBO(
          200 + random.nextInt(55), // R: 200-255
          200 + random.nextInt(55), // G: 200-255
          200 + random.nextInt(55), // B: 200-255
          0.8, // 80% opacity
        );
      }
      return medicineColors[medicineId]!;
    }

    return Card(
      elevation: 3,
      color: getRandomColor(medicine.id),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 12.0,
        ), // Added top padding to lower the image
        child: Column(
          children: [
            Container(
              height: 80,
              width: 130,
              margin: const EdgeInsets.only(bottom: 4), // Added bottom margin
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  8,
                ), // Rounded corners for image
                color: Colors.white.withOpacity(0.3), // Slight white overlay
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    medicine['image'] != null && medicine['image'].isNotEmpty
                        ? Image.file(
                          File(medicine['image']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'lib/assets/order_medicine.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                        : Image.asset(
                          'lib/assets/order_medicine.jpg',
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                medicine['name'] ?? 'Unknown Medicine',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "Price: BDT ${medicine['price'] ?? 'N/A'}",
                style: TextStyle(fontSize: 13, color: Colors.grey[700],
                 fontWeight: FontWeight.bold,),
                 maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: const Color.fromARGB(255, 3, 73, 5),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditMedicine(medicineId: medicine.id),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: const Color.fromARGB(255, 221, 128, 121),
                  onPressed: () => _deleteMedicine(medicine.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorizedMedicines(List<DocumentSnapshot> medicines) {
    // Group medicines by category
    Map<String, List<DocumentSnapshot>> categorizedMedicines = {};
    for (var med in medicines) {
      String category = med['category'] ?? 'Uncategorized';
      if (!categorizedMedicines.containsKey(category)) {
        categorizedMedicines[category] = [];
      }
      categorizedMedicines[category]!.add(med);
    }

    return ListView.builder(
      itemCount: categorizedMedicines.keys.length,
      itemBuilder: (context, index) {
        final category = categorizedMedicines.keys.elementAt(index);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categorizedMedicines[category]!.length,
                  itemBuilder: (context, itemIndex) {
                    return SizedBox(
                      width: 180,
                      child: _buildMedicineCard(
                        categorizedMedicines[category]![itemIndex],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(List<DocumentSnapshot> medicines) {
    final filteredMedicines =
        medicines.where((medicine) {
          final name = medicine['name']?.toString().toLowerCase() ?? '';
          return name.contains(searchQuery);
        }).toList();

    if (filteredMedicines.isEmpty) {
      return const Center(
        child: Text('No medicines found matching your search.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: filteredMedicines.length,
      itemBuilder: (context, index) {
        return _buildMedicineCard(filteredMedicines[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: medicinesCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No medicines available.'));
                }

                var medicines = snapshot.data!.docs;

                if (searchQuery.isNotEmpty) {
                  return _buildSearchResults(medicines);
                } else {
                  return _buildCategorizedMedicines(medicines);
                }
              },
            ),
          ),
        ],
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
