import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Orders extends StatefulWidget {
  const Orders({Key? key}) : super(key: key);

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    if (user == null) return [];

    QuerySnapshot querySnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: user!.uid)
        // .orderBy('createdAt', descending: true)
        .get();
    debugPrint("Current User ID: ${user?.uid}");

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                  title: Text(
                    'Order ID: ${order['orderId']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order['status']}'),
                      Text('Total: BDT ${order['totalAmount'].toStringAsFixed(2)}'),
                      Text(
                        'Delivery Date: ${DateFormat('MMM dd, yyyy').format(order['deliveryDate'].toDate())}',
                      ),
                    ],
                  ),
                  tileColor: Colors.grey[100],
                  onTap: () {
                    // Navigate to order details if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
