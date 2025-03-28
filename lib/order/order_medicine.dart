import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderMedicine extends StatefulWidget {
  const OrderMedicine({super.key});

  @override
  State<OrderMedicine> createState() => _OrderMedicineState();
}

class _OrderMedicineState extends State<OrderMedicine> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
            ).colorScheme.surfaceVariant.withOpacity(0.4),
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

  Widget _buildMedicineImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Center(child: Icon(Icons.medication, size: 40));
    }

    // Handle both network and file paths
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return const Center(child: Icon(Icons.medication, size: 40));
  }

  Widget _buildMedicineCard(DocumentSnapshot medicine) {
    final data = medicine.data() as Map<String, dynamic>;

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey.shade200,
              ),
              child: _buildMedicineImage(data['image']),
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

                  // const SizedBox(height: 1),
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
                      onPressed: () => _addToCart(data),
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

  void _addToCart(Map<String, dynamic> medicineData) {
    debugPrint('Added to cart: ${medicineData['name']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Medicine'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _searchQuery.isEmpty
                      ? _firestore
                          .collection('medicines')
                          .orderBy('category')
                          .snapshots()
                      : _firestore
                          .collection('medicines')
                          .where('searchKeywords', arrayContains: _searchQuery)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No medicines found'));
                }

                final medicinesByCategory = <String, List<DocumentSnapshot>>{};
                for (final doc in snapshot.data!.docs) {
                  final category = doc['category'] ?? 'Uncategorized';
                  medicinesByCategory.putIfAbsent(category, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      medicinesByCategory.entries
                          .map(
                            (entry) =>
                                _buildCategorySection(entry.key, entry.value),
                          )
                          .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
