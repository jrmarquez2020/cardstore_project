import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class myOrder extends StatefulWidget {
  const myOrder({Key? key}) : super(key: key);

  @override
  State<myOrder> createState() => _myOrderState();
}

class _myOrderState extends State<myOrder> {
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final ordersSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('myOrders')
            .get();

    List<Map<String, dynamic>> orders = [];

    for (var orderDoc in ordersSnapshot.docs) {
      final orderData = orderDoc.data();
      orderData['id'] = orderDoc.id; // include the doc ID
      orders.add(orderData);
    }

    print(orders); // For debugging
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        title: const Text('My order', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F689F),
        automaticallyImplyLeading: true,
      ),
      backgroundColor: Color(0xFF1F689F),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No Orders Yet!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final orders = snapshot.data!;

          final pendingOrders =
              orders
                  .where(
                    (order) =>
                        (order['status'] ?? '').toString().toLowerCase() ==
                        'pending',
                  )
                  .toList();

          final transitOrders =
              orders
                  .where(
                    (order) =>
                        (order['status'] ?? '').toString().toLowerCase() ==
                        'transit',
                  )
                  .toList();

          final deliveredOrders =
              orders
                  .where(
                    (order) =>
                        (order['status'] ?? '').toString().toLowerCase() ==
                        'delivered',
                  )
                  .toList();

          Widget buildOrderSection(
            String title,
            List<Map<String, dynamic>> data,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                data.isNotEmpty
                    ? Column(
                      children:
                          data.map((order) {
                            final items = List<Map<String, dynamic>>.from(
                              order['items'] ?? [],
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...items.map((item) {
                                  return Card(
                                    color: Colors.black38,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      leading: Image.network(
                                        item['image'] ??
                                            'https://via.placeholder.com/50',
                                        fit: BoxFit.cover,
                                        height: 50,
                                        width: 50,
                                      ),
                                      title: Text(
                                        item['name'] ?? 'No Name',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '₱${item['price']?.toString() ?? '0'} x ${item['quantity']?.toString() ?? '1'}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      trailing: Text(
                                        '₱${item['total']?.toString() ?? '0'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const Divider(
                                  color: Colors.white24,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                    )
                    : const Text(
                      'No orders in this category.',
                      style: TextStyle(color: Colors.white70),
                    ),
                const SizedBox(height: 20),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildOrderSection('Pending Orders', pendingOrders),
              buildOrderSection('In Transit Orders', transitOrders),
              buildOrderSection('Delivered Orders', deliveredOrders),
            ],
          );
        },
      ),
    );
  }
}
