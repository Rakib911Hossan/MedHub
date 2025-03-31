import 'dart:io';
import 'package:badges/badges.dart' as custom_badge;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_project/order/cartPage.dart';
import 'package:new_project/order/empty_cart_page.dart';

class MedicineDetailsPage extends StatefulWidget {
  final String medicineId;
  final Map<String, dynamic> medicine;

  const MedicineDetailsPage({
    super.key,
    required this.medicineId,
    required this.medicine,
  });

  @override
  State<MedicineDetailsPage> createState() => _MedicineDetailsPageState();
}

class _MedicineDetailsPageState extends State<MedicineDetailsPage> {
  int _quantity = 1;
  int _cartItemCount = 0; // Initialize cart item count
  DocumentSnapshot? medicineSnapshot;
  int _currentStep = 1; // Moved to state
  late final TextEditingController _stepController = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    _fetchMedicineDetails();
  }

  Future<void> _fetchMedicineDetails() async {
    try {
      medicineSnapshot =
          await FirebaseFirestore.instance
              .collection('medicines')
              .doc(widget.medicineId) // Use the ID from constructor
              .get();

      if (!medicineSnapshot!.exists) {
        throw Exception('Medicine not found');
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching medicine: $e');
      _showSnackBar('Failed to load medicine details');
    }
  }

  Future<void> _addToCart() async {
    try {
      debugPrint('Adding medicine: ${widget.medicine['name']}');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to add items to cart');
        return;
      }
      final cartId =
          'CRT${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final medicineName =
          widget.medicine['name']?.toString() ?? 'Unknown Medicine';
      final company = widget.medicine['company']?.toString() ?? '';
      final price = (widget.medicine['price'] as num?)?.toDouble() ?? 0.0;
      final availableQuantity =
          (widget.medicine['quantity'] as num?)?.toInt() ?? 0;
      if (_quantity > availableQuantity) {
        _showSnackBar(
          'Only $availableQuantity items available. Please reduce the quantity.',
        );
        return;
      }
      final discountPrice =
          (widget.medicine['discount_price_each'] as num?)?.toDouble() ?? 0.0;

      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final cartDoc = await transaction.get(cartRef);

        final newCartItem = {
          'medicineId': widget.medicineId,
          'name': medicineName,
          'price': price,
          'discount_price_each': discountPrice,
          'company': company,
          'generic_group': widget.medicine['generic_group']?.toString() ?? '',
          'image': widget.medicine['image']?.toString() ?? '',
          'quantity': _quantity,
          'total_price': price * _quantity,
          'total_discount_price': discountPrice * _quantity,
        };

        if (cartDoc.exists) {
          final medicines = List<Map<String, dynamic>>.from(
            cartDoc['medicines'] ?? [],
          );

          // Remove all previous versions of this medicine
          final updatedMedicines =
              medicines
                  .where(
                    (item) =>
                        !(item['name'] == medicineName &&
                            item['company'] == company),
                  )
                  .toList();

          // Add the new version (replacing all previous)
          updatedMedicines.add(newCartItem);

          // Calculate totals
          final totalDiscount = updatedMedicines.fold<double>(
            0.0,
            (sum, item) =>
                sum + (item['total_discount_price'] as num).toDouble(),
          );
          final totalPrice = updatedMedicines.fold<double>(
            0.0,
            (sum, item) => sum + (item['total_price'] as num).toDouble(),
          );
          final totalAfterDiscount = totalPrice - totalDiscount;

          transaction.update(cartRef, {
            'medicines': updatedMedicines,
            'whole_cart_discount_price': totalAfterDiscount,
            'whole_cart_total_price': totalPrice,
            'whole_cart_price_after_discount': totalDiscount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new cart with this item
          transaction.set(cartRef, {
            'uid': user.uid,
            'cartId': cartId,
            'medicines': [newCartItem],
            'whole_cart_discount_price': discountPrice * _quantity,
            'whole_cart_total_price': price * _quantity,
            'whole_cart_price_after_discount':
                (price - discountPrice) * _quantity,
            'cartConfirmed': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      _showSnackBar('$medicineName (x$_quantity) added to cart');
    } on FirebaseException catch (e) {
      debugPrint('Firestore Error: ${e.code} - ${e.message}');
      _showSnackBar('Failed to update cart: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('Cart Error: $e\n$stackTrace');
      _showSnackBar('Failed to add to cart: ${e.toString()}');
    }
  }

  // ==================== UI HELPERS ====================
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildImageSection() {
    final medicine = widget.medicine;
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              medicine['image']?.isNotEmpty == true
                  ? Image.file(
                    File(medicine['image']),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackImage(),
                  )
                  : _buildFallbackImage(),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset('lib/assets/order_medicine.jpg', fit: BoxFit.cover);
  }

  Widget _buildQuantitySelector() {
    // Initialize with step 1

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label and step input
          Row(
            children: [
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 15, 13, 13),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _stepController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Step',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final newStep = int.tryParse(value) ?? 0;
                    if (newStep >= 1) {
                      _currentStep = newStep;
                      _stepController.text =
                          newStep.toString(); // Update display
                    } else {
                      _currentStep = 1;
                      _stepController.text = '';
                    }
                  },
                ),
              ),
            ],
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(
                      () =>
                          _quantity =
                              _quantity > _currentStep
                                  ? _quantity - _currentStep
                                  : 1,
                    );
                  },
                ),
                Container(
                  width: 40,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _quantity += _currentStep);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final medicine = widget.medicine;
    final totalPrice = (medicine['price'] ?? 0.0) * _quantity;
    final totalDiscountPrice =
        (medicine['discount_price_each'] ?? 0.0) * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine['name'] ?? 'Medicine Details'),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _getCartItemCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: custom_badge.Badge(
                  position: custom_badge.BadgePosition.topEnd(
                    top: -10,
                    end: -10,
                  ),
                  badgeContent: Text('$count'),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      // Get the current cart count
                      final currentCount = await _getCartItemCount().first;
                      // Navigate to CartPage with empty state if count is 0
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  currentCount == 0
                                      ? const EmptyCartPage() // Create this widget for empty state
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Section
            _buildImageSection(),
            const SizedBox(height: 10),

            // 2. Basic Info
            Text(
              medicine['name'] ?? 'Unknown Medicine',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (medicine['company'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'By ${medicine['company']}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 5),

            // 3. Price Display
            Text(
              'Price: BDT ${(medicine['price'] ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),

            // 3. Discount Price Display (if available)
            Text(
              'Discount Price: BDT ${(medicine['discount_price_each'] ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            // 5. Quantity Selector
            _buildQuantitySelector(),

            const SizedBox(height: 10),

            // 6. Total Price
            Text(
              'Total: BDT ${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (medicine['discount_amount'] != null) ...[
              Text(
                'Total Discount Price: \BDT ${totalDiscountPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 7. Add to Cart Button
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _addToCart();
                },
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Description (if available)
            if (medicine['description'] != null) ...[
              const Text(
                'Description:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                medicine['description'],
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
