import 'package:afitnessgym/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_product_detail_screen.dart';
import 'user_cart_screen.dart';
import 'user_my_orders.dart';

class StrengthTrainingScreen extends StatefulWidget {
  const StrengthTrainingScreen({super.key});

  @override
  _StrengthTrainingScreenState createState() => _StrengthTrainingScreenState();
}

class _StrengthTrainingScreenState extends State<StrengthTrainingScreen> {
  List<Map<String, dynamic>> products = [];
  List<String> favoriteIds = [];
  // Map<bool> favoriteStatuses = {};
  List<bool> favorites = [];

  @override
  void initState() {
    super.initState();

    fetchProductsFromFirestore();
  }

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  Future<void> fetchProductsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('items').get();
      final fetchedProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'name': data['name'],
              'price': 'PHP${data['price'].toStringAsFixed(2)} ',
              'image': data['image'],
              'description': data['description'],
              'stocks': data['stocks'],
              'id': data['id'],
            };
          }).toList();

      setState(() {
        products = fetchedProducts;
        filteredProducts = fetchedProducts; // copy for display and search
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  void searchProducts(String query) {
    final results =
        products.where((product) {
          final nameLower = product['name'].toLowerCase();
          final searchLower = query.toLowerCase();

          return nameLower.contains(searchLower);
        }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
              (Route<dynamic> route) => true, // remove all previous routes
            );
          },
          icon: Icon(Icons.person_2_outlined, size: 40),
        ),
        backgroundColor: Color(0xFF1F689F), // optional
        title: Center(
          child: Image.asset('assets/images/caverologo.jpg', width: 80),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
                (Route<dynamic> route) => true, // remove all previous routes
              );
            },
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black,
              size: 40,
            ),
          ),
        ],
      ),

      backgroundColor: Color(0xFF1F689F),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛒 GridView of Products
            filteredProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: .6,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isFavorites =
                        favorites.length > index && favorites[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailScreen(
                                  id: product['id'],
                                  productName: product['name'],
                                  productPrice: product['price'],
                                  productImage: product['image'],
                                  productDescription: product['description'],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF12476F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 30, 8, 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.network(
                                product['image'],
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  product['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 40),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    product['price'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 177, 177, 177),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
