import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_project/order/deliveryAddress.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false; 

  Future<Map<String, dynamic>?> _getUserData() async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('user_info')
        .doc(user!.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        centerTitle: true,
        actions: [
          Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
           onTap: () async {
                final userData = await _getUserData();
                if (userData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not found')),
                  );
                  return;
                }
                
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryAddressPage(
                      user: user!,
                      initialAddress: userData['address'] ?? '',
                      initialPhone: userData['phone']?.toString() ?? '',
                    ),
                  ),
                );
                
                if (result != null && mounted) {
                  setState(() {
                    // Update local state if needed
                  });
                }
              },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
          Icon(Icons.home),
          Text(
            'Address',
            style: TextStyle(fontSize: 10),
          ),
            ],
          ),
        ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Your cart is empty'));
          }

          final cartData = snapshot.data!.data() as Map<String, dynamic>;
          final medicines = List<Map<String, dynamic>>.from(cartData['medicines'] ?? []);

          if (medicines.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    return _buildMedicineCard(medicine);
                  },
                ),
              ),
              _buildTotalSection(cartData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Medicine Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: medicine['image']?.isNotEmpty == true
                  ? Image.file(
                    File(medicine['image']),
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.medication, size: 40),
            ),
            const SizedBox(width: 12),
            
            // Medicine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine['name'] ?? 'Unknown Medicine',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    medicine['company'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${medicine['quantity']} × BDT ${medicine['price']?.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Price and Actions
            Column(
              children: [
                 if ((medicine['total_discount_price'] ?? 0) > 0)
                  Text(
                    'BDT ${medicine['total_discount_price']?.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    fontSize: 16,
                    ),
                  ),
                Text(
                  'BDT ${medicine['total_price']?.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: (medicine['total_discount_price'] ?? 0) > 0
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                    color: (medicine['total_discount_price'] ?? 0) > 0
                    ? Colors.grey
                    : Colors.black,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromCart(medicine['medicineId']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildTotalSection(Map<String, dynamic> cartData) {
  final total = (cartData['whole_cart_total_price'] ?? 0).toDouble();
  final totalDiscount = (cartData['whole_cart_discount_price'] ?? 0).toDouble();
  final totalPriceAfterDisc = (cartData['whole_cart_price_after_discount'] ?? total).toDouble();
  final deliveryCharge = 70.0;
  final showDeliveryCharge = totalPriceAfterDisc < 1000; // Assuming free delivery for orders over 1000
  final grandTotal = showDeliveryCharge ? totalPriceAfterDisc + deliveryCharge : totalPriceAfterDisc;
  final deliveryDate = DateTime.now().add(const Duration(days: 1)).toLocal().toString().split(' ')[0];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border(top: BorderSide(color: Colors.grey[300]!)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 16)),
            Text('BDT ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
          ],
        ),
        if (totalDiscount > 0) ...[
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price after discount:', style: TextStyle(fontSize: 16)),
              Text('BDT ${totalPriceAfterDisc.toStringAsFixed(2)}', 
                  style: const TextStyle(color: Colors.green, fontSize: 16)),
            ],
          ),
        ],
        if (showDeliveryCharge) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Charge:', style: TextStyle(fontSize: 16)),
              Text('BDT ${deliveryCharge.toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ] else ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery:', style: TextStyle(fontSize: 16)),
              Text('FREE', 
                  style: const TextStyle(color: Colors.green, fontSize: 16)),
            ],
          ),
        ],
          Text(
          'Delivery charge wont be applied for orders over BDT 1000',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'BDT ${grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Estimated Delivery Date: $deliveryDate',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        
        const SizedBox(height: 16),
        SizedBox(
          width: 188,
          child: ElevatedButton(
            onPressed: _confirmOrder,
            child: const Text('Comfirm Order'),
          ),
        ),
      ],
    ),
  );
}

 Future<void> _removeFromCart(String medicineId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartDoc = await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .get();

    if (!cartDoc.exists) return;

    final medicines = List<Map<String, dynamic>>.from(cartDoc.data()!['medicines'] ?? []);
    final medicineToRemove = medicines.firstWhere(
      (item) => item['medicineId'] == medicineId,
      orElse: () => {},
    );

    if (medicineToRemove.isEmpty) return;

    // Calculate the differences to subtract from current totals
    final itemTotalPrice = (medicineToRemove['total_price'] ?? 0).toDouble();
    final itemTotalDiscount = (medicineToRemove['total_discount_price'] ?? 0).toDouble();
    final itemPriceAfterDisc = itemTotalPrice - itemTotalDiscount;

    // Prepare the update data
    final updatedCartData = {
      'medicines': FieldValue.arrayRemove([medicineToRemove]),
      'updatedAt': FieldValue.serverTimestamp(),
      'whole_cart_total_price': FieldValue.increment(-itemTotalPrice),
      'whole_cart_discount_price': FieldValue.increment(-itemTotalDiscount),
      'whole_cart_price_after_discount': FieldValue.increment(-itemPriceAfterDisc),
    };

    await FirebaseFirestore.instance
      .collection('carts')
      .doc(user.uid)
      .update(updatedCartData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: ${e.toString()}')),
      );
    }
    debugPrint('Error removing from cart: $e');
  }
}

 Future<void> _confirmOrder() async {
  if (user == null) return;

  setState(() => _isLoading = true);

  try {
    // 1. Generate random order ID
    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final deliveryDate = DateTime.now().add(const Duration(days: 3)); // 3 days from now
    
    // 2. Get current cart data
    final cartDoc = await FirebaseFirestore.instance
        .collection('carts')
        .doc(user!.uid)
        .get();
    
    if (!cartDoc.exists) throw Exception('Cart not found');

    // 3. Create new order document
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .set({
          'orderId': orderId,
          'userId': user!.uid,
          'cartId': cartDoc['cartId'], // Using user ID as cart ID if 1:1
          'items': cartDoc.data()!['medicines'],
          'deliveryDate': deliveryDate,
          'deliveryMan': '', // To be assigned later
          'deliveryPhone': '', // To be assigned later
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'totalAmount': cartDoc.data()!['whole_cart_price_after_discount'] ?? 0,
        });

    // 4. Update cart status
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user!.uid)
        .update({
          'cartConfirmed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // 5. Show success and navigate
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId confirmed!')),
      );
      Navigator.pushNamed(context, '/order-confirmation', arguments: orderId);
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm order: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
}