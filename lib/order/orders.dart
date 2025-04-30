import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userRole = 'user';
  String userName = 'User';
  String phoneNumber = 'Phone Number';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('user_info')
                .doc(user!.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            userRole = userDoc['role'] ?? 'user';
            userName =
                userDoc['name']?.toString() ?? // Ensure string conversion
                user?.displayName ??
                user?.email?.split('@').first ??
                'User';

            // Handle phone number conversion from int to String
            final dynamic phoneData = userDoc['phone'];
            phoneNumber =
                phoneData != null
                    ? phoneData
                        .toString() // Convert number to string
                    : 'Phone Number';
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        setState(() {
          userName = user?.email?.split('@').first ?? 'User';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    if (user == null) return [];

    QuerySnapshot querySnapshot =
        await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Ensure the document ID is included for deletion
      data['documentId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _deleteOrder(String documentId) async {
    try {
      await _firestore.collection('orders').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
      setState(() {}); // Refresh the list after deletion
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting order: $error')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[100]!;
      case 'confirmed':
        return Colors.blue[100]!;
      case 'delivered':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.local_shipping;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        centerTitle: true,
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
              final status = order['status'].toString().toLowerCase();
              final isPending = status == 'pending';
              final isConfirmed = status == 'confirmed';
              final canConfirm =
                  (userRole == 'admin' || userRole == 'deliveryMan') &&
                  isPending;
              final canDeliver =
                  (userRole == 'deliveryMan' || userRole == 'admin') &&
                  isConfirmed;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: _getStatusColor(status),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Order #${order['orderId']} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (isPending || userRole == 'admin')
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _showDeleteConfirmationDialog(
                                        context,
                                        order['documentId'],
                                      ),
                                ),
                              if (canConfirm)
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                      () => _showConfirmationDialog(
                                        order,
                                        userRole,
                                        userName,
                                        phoneNumber,
                                      ),
                                ),
                              if (canDeliver)
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_box,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                      () => _showDeliveredConfirmationDialog(
                                        order,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${order['status']}',
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Total: BDT ${order['totalAmount'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(order['createdAt'].toDate())}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delivery Date: ${DateFormat('MMM dd, yyyy').format(order['deliveryDate'].toDate())}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address: ${order['userAddress']}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (order['deliveryMan'] != null &&
                          order['deliveryMan'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Delivery Man: ${order['deliveryMan']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      if (order['deliveryPhone'] != null &&
                          order['deliveryPhone'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Contact: ${order['deliveryPhone']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String documentId,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this order?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                await _deleteOrder(documentId); // Then perform deletion
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmationDialog(
    Map<String, dynamic> order,
    String userRole,
    String userName,
    String phoneNumber,
  ) async {
    final deliveryManController = TextEditingController(
      text: userRole == 'admin' ? (order['deliveryMan'] ?? '') : userName,
    );
    final phoneController = TextEditingController(
      text:
          userRole == 'admin'
              ? (order['deliveryPhone']?.toString() ?? '')
              : phoneNumber.toString(),
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Common confirmation message
                TextFormField(
                  controller:
                      deliveryManController, // Use the pre-initialized controller
                  decoration: InputDecoration(
                    labelText: 'Delivery Man Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: userRole != 'admin' ? Colors.grey[200] : null,
                  ),
                  readOnly: userRole != 'admin',
                  style: TextStyle(
                    color: userRole != 'admin' ? Colors.grey[600] : null,
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller:
                      phoneController, // Use the pre-initialized controller
                  decoration: InputDecoration(
                    labelText: 'Contact Phone',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: userRole != 'admin' ? Colors.grey[200] : null,
                  ),
                  keyboardType: TextInputType.phone,
                  readOnly: userRole != 'admin',
                  style: TextStyle(
                    color: userRole != 'admin' ? Colors.grey[600] : null,
                  ),
                  validator:
                      userRole == 'admin'
                          ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          }
                          : null,
                ),
                if (userRole == 'deliveryMan') ...[
                  const SizedBox(height: 15),
                  const Text(
                    'By confirming, you accept responsibility for this delivery',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                if (phoneController.text.isEmpty ||
                    deliveryManController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order['documentId'])
                      .update({
                        'status': 'confirmed',
                        'confirmedBy': userName,
                        'updatedAt': FieldValue.serverTimestamp(),
                        if (userRole == 'admin') ...{
                          'deliveryMan': deliveryManController.text,
                          'deliveryPhone': phoneController.text,
                        },
                        if (userRole == 'deliveryMan') ...{
                          'deliveryMan': userName,
                          'deliveryPhone': phoneNumber,
                        },
                        'confirmedAt': FieldValue.serverTimestamp(),
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Order confirmed successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeliveredConfirmationDialog(
    Map<String, dynamic> order,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delivery'),
            content: const Text(
              'Have you successfully delivered this order to the customer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(order['documentId'])
                        .update({
                          'status': 'delivered',
                          'deliveredAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Order marked as delivered'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    setState(() {});
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text(
                  'Confirm Delivery',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
