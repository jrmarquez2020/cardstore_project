import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_checkout_screen.dart'; // Import the CheckoutScreen

class ProductDetailScreen extends StatefulWidget {
  final String id;
  final String productName;
  final String productPrice;
  final String productImage;
  final String productDescription;

  const ProductDetailScreen({
    Key? key,
    required this.id,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productDescription,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedIndex = 0;

  Future<void> addToCart(String itemId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartDocRef = FirebaseFirestore.instance
        .collection('items')
        .doc(itemId)
        .collection('addCart')
        .doc(userId); // Use user ID as the doc ID

    final docSnapshot = await cartDocRef.get();

    if (docSnapshot.exists) {
      // If already in cart, increment the quantity
      final currentQuantity = docSnapshot.data()?['quantity'] ?? 0;
      await cartDocRef.update({
        'quantity': currentQuantity + 1,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // If not in cart, create with quantity 1
      await cartDocRef.set({
        'check': false,
        'userId': userId,
        'quantity': 1,
        'addedAt': Timestamp.now(),
      });
      print('Added to cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Detail',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1F689F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Color(0xFF1F689F),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Color(0xFF12476F),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    // Product Image (Smaller size)
                    Image.network(
                      widget.productImage,
                      height: 200,
                      // Reduced the image height
                      width: 200,
                    ),

                    const SizedBox(height: 40),

                    // Product Name
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      widget.productPrice,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      widget.productDescription,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 150),
            ElevatedButton(
              onPressed:
                  () => {
                    addToCart(widget.id),
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Added to Cart'))),
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF12476F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
