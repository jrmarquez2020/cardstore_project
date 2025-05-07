// checkout_screen.dart
import 'package:afitnessgym/user_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/cart_data.dart'; // Import the global cart list

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final fullname = TextEditingController();
  final phone_number = TextEditingController();
  final address = TextEditingController();

  String selectedMethod = '';
  double getTotalPrice() {
    double total = 0.0;
    for (var item in cartItems) {
      // Clean the price string to remove non-numeric characters (except the decimal point)
      String cleanedPrice = item.price.replaceAll(RegExp(r'[^\d.]'), '');
      double itemPrice = double.tryParse(cleanedPrice) ?? 0.0;
      total += itemPrice;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    fetchUserCartWithTotal();
  }

  Future<Map<String, dynamic>> fetchUserCartWithTotal() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {'items': [], 'total': 0.0};

    final itemsCollection = FirebaseFirestore.instance.collection('items');
    final allItemsSnapshot = await itemsCollection.get();

    List<Map<String, dynamic>> cartItems = [];
    double grandTotal = 0.0;

    for (var itemDoc in allItemsSnapshot.docs) {
      final itemId = itemDoc.id;
      final price = (itemDoc.data()['price'] ?? 0).toDouble();

      final cartDoc =
          await itemsCollection
              .doc(itemId)
              .collection('addCart')
              .doc(userId)
              .get();

      if (cartDoc.exists) {
        final cartData = cartDoc.data();
        final quantity = (cartData?['quantity'] ?? 0).toInt();
        final check = cartData?['check'] ?? false;

        if (check == true) {
          final itemTotal = price * quantity;
          grandTotal += itemTotal;

          cartItems.add({
            'itemId': itemId,
            'name': itemDoc.data()['name'] ?? 'No Name',
            'image': itemDoc.data()['image'] ?? '',
            'price': price,
            'quantity': quantity,
            'total': itemTotal,
            'check': check,
          });
        }
      }
    }

    return {'items': cartItems, 'total': grandTotal};
  }

  Future<void> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final email = user.email ?? 'no-email';

    try {
      // 1. Validate form fields
      if (fullname.text.isEmpty ||
          phone_number.text.isEmpty ||
          address.text.isEmpty) {
        print('Missing full name, phone number, or address.');
        return;
      }

      // 2. Fetch user profile
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (!userDoc.exists) {
        print('User profile not found.');
        return;
      }

      final userData = userDoc.data()!;
      final firstName = userData['firstName'] ?? 'no-first-name';
      final lastName = userData['lastName'] ?? 'no-last-name';

      // 3. Fetch checked cart items and total
      final cartData = await fetchUserCartWithTotal();
      final allItems = cartData['items'] as List<Map<String, dynamic>>;
      final total = (cartData['total'] as num).toDouble();

      if (allItems.isEmpty) {
        print('No items selected for order.');
        return;
      }

      // 4. Create order document
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderData = {
        'modeOfPayment': selectedMethod,
        'orderId': orderRef.id,
        'address': address.text,
        'contact': phone_number.text,
        'fullName': fullname.text,
        'userId': userId,
        'email': email,
        'items': allItems,
        'total': total,
        'orderedAt': Timestamp.now(),
        'status': 'pending',
      };

      // 5. Save order to both collections
      await orderRef.set(orderData);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection("myOrders")
          .doc(orderRef.id)
          .set(orderData);

      print('Order placed successfully!');

      // 6. Remove only checked items from cart
      for (var item in allItems) {
        final itemId = item['itemId'];
        await FirebaseFirestore.instance
            .collection('items')
            .doc(itemId)
            .collection('addCart')
            .doc(userId)
            .delete();
      }

      print('Checked items removed from cart.');
    } catch (e) {
      print('Error placing order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total price
    double total = cartItems.fold(
      0,
      (sum, item) =>
          sum +
          double.parse(
            item.price
                .replaceAll('₱', '')
                .replaceAll(',', '')
                .replaceAll(' PHP', ''),
          ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1F689F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      backgroundColor: Color(0xFF1F689F),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: fetchUserCartWithTotal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    (snapshot.data?['items'] as List).isEmpty) {
                  return const Center(
                    child: Text(
                      'No items in cart!',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                // ✅ PLACE IT HERE:
                final cartItems =
                    snapshot.data!['items'] as List<Map<String, dynamic>>;
                final total =
                    (snapshot.data!['total'] as num)
                        .toDouble(); // ✅ this line right here

                return Column(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                            child: Column(
                              children: [
                                Text(
                                  "Add your delivery address",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                TextField(
                                  controller: fullname,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    label: Text(
                                      "Fullname",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  controller: phone_number,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    label: Text(
                                      "Phone Number",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 30),
                                TextField(
                                  controller: address,
                                  style: TextStyle(color: Colors.black),
                                  minLines: 3, // Makes the height taller
                                  maxLines: 5, // Optional: allow it to grow
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    label: Text(
                                      "Address",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),
                                Text(
                                  "Payment Method",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedMethod = 'Cash on Delivery';
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            selectedMethod == 'Cash on Delivery'
                                                ? const Color.fromARGB(
                                                  255,
                                                  58,
                                                  66,
                                                  183,
                                                )
                                                : Colors.grey,
                                      ),
                                      child: Text(
                                        "Cash on Delivery",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedMethod = 'Gcash';
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            selectedMethod == 'Gcash'
                                                ? Colors.deepPurple
                                                : Colors.grey,
                                      ),
                                      child: Text(
                                        "Gcash",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 269),
                          Container(
                            color: Colors.black38,
                            child: Column(
                              children: [
                                SizedBox(height: 15),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    25,
                                    0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Subtotal: ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'PHP${total.toStringAsFixed(2)}', // this will now work!
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            placeOrder();
                                            confirmation_dialog(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF1F689F),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 100,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Buy',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Display Total
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show success dialog after placing order
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Order Successful'),
            content: const Text('Thank you for your purchase!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void confirmation_dialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure to your order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Yes
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                cartItems.clear();
                Navigator.of(context).pop(true);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StrengthTrainingScreen(),
                  ),
                  (Route<dynamic> route) => false, // remove all previous routes
                );
                _showSuccessDialog(context);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
