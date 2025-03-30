import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _confirmCart,
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
                  ? Image.network(
                      medicine['image'],
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
                    '${medicine['quantity']} × \$${medicine['price']?.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Price and Actions
            Column(
              children: [
                Text(
                  '\$${medicine['total_price']?.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if ((medicine['total_discount_price'] ?? 0) > 0)
                  Text(
                    '\$${medicine['total_discount_price']?.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green,
                      decoration: TextDecoration.lineThrough,
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
    final medicines = List<Map<String, dynamic>>.from(cartData['medicines'] ?? []);
    final total = medicines.fold<double>(0, (sum, item) => sum + (item['total_price'] ?? 0));
    final totalDiscount = medicines.fold<double>(0, (sum, item) => sum + (item['total_discount_price'] ?? 0));

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
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            ],
          ),
          if (totalDiscount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount:', style: TextStyle(fontSize: 16)),
                Text('-\$${(total - totalDiscount).toStringAsFixed(2)}', 
                    style: const TextStyle(color: Colors.green, fontSize: 16)),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '\$${totalDiscount > 0 ? totalDiscount.toStringAsFixed(2) : total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmCart,
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromCart(String medicineId) async {
    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user?.uid)
          .update({
            'medicines': FieldValue.arrayRemove([{'medicineId': medicineId}]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmCart() async {
    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user?.uid)
          .update({
            'cartConfirmed': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      // Navigate to checkout or show success message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm cart: ${e.toString()}')),
      );
    }
  }
}