// order_medicine_screen.dart
import 'package:flutter/material.dart';

class OrderMedicine extends StatelessWidget {
  const OrderMedicine({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Medicine'),
      ),
      body: const Center(
        child: Text('Order Medicine Screen Content'),
      ),
    );
  }
}