import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' as custom_badge;
import 'package:new_project/cart/add_to_cart.dart';
import 'package:new_project/cart/cartPage.dart';
import 'package:new_project/cart/empty_cart_page.dart';
import 'package:new_project/screen/home_screen.dart';

class OrderMedicine extends StatefulWidget {
  const OrderMedicine({super.key});

  @override
  State<OrderMedicine> createState() => _OrderMedicineState();
}

class _OrderMedicineState extends State<OrderMedicine> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CollectionReference medicinesCollection = FirebaseFirestore.instance
      .collection('medicines');
  final int _cartItemCount = 0; // Initialize cart item count

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            hintText: 'Search medicines...',
            prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
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
              (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(DocumentSnapshot medicine) {
    final data = medicine.data() as Map<String, dynamic>;
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

    return SizedBox(
      width: 170,
      child: Card(
        elevation: 3,
        color: getRandomColor(medicine.id),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // Image Section
            Container(
              height: 99,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
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

            // Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data['name'] ?? 'Unnamed Medicine',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          data['company'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    'BDT ${data['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MedicineDetailsPage(
                                  medicineId: medicine.id,
                                  medicine:
                                      medicine.data() as Map<String, dynamic>,
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String category,
    List<DocumentSnapshot> medicines,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          category,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: medicines.length,
            itemBuilder:
                (context, index) => _buildMedicineCard(medicines[index]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Stream<int> _getCartItemCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return 0;
          final medicines = snapshot['medicines'] as List?;
          final cartConfirmed = snapshot['cartConfirmed'] as bool? ?? true;
          return (cartConfirmed == false) ? (medicines?.length ?? 0) : 0;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Medicine'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Left arrow icon
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ), // Navigate to HomePage
            );
          },
        ),
        actions: [
          StreamBuilder<int>(
            stream: _getCartItemCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: custom_badge.Badge(
                  alignment: Alignment.topRight,
                  label: Text('$count'),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final currentCount = await _getCartItemCount().first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  currentCount == 0
                                      ? const EmptyCartPage() // Show empty cart page if count is 0
                                      : const CartPage(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: medicinesCollection.snapshots(),
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle error state
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading medicines',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // Handle no data state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No medicines available'
                          : 'No medicines found',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                final allMedicines = snapshot.data!.docs;

                // If searching, show filtered results
                if (_searchQuery.isNotEmpty) {
                  return _buildSearchResults(allMedicines);
                }

                // Otherwise group by category
                final medicinesByCategory = <String, List<DocumentSnapshot>>{};
                for (final doc in allMedicines) {
                  final category =
                      doc['category'] as String? ?? 'Uncategorized';
                  medicinesByCategory.putIfAbsent(category, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      medicinesByCategory.entries.map((entry) {
                        return _buildCategorySection(entry.key, entry.value);
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<DocumentSnapshot> medicines) {
    final filteredMedicines =
        medicines.where((medicine) {
          final name = medicine['name']?.toString().toLowerCase() ?? '';
          final generic =
              medicine['generic_group']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase()) ||
              generic.contains(_searchQuery.toLowerCase());
        }).toList();

    if (filteredMedicines.isEmpty) {
      return Center(
        child: Text(
          'No medicines found for "$_searchQuery"',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [_buildCategorySection('Search Results', filteredMedicines)],
    );
  }
}
