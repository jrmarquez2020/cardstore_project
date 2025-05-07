import 'package:afitnessgym/admin/admin_orders.dart';
import 'package:afitnessgym/admin/admin_products.dart';
import 'package:afitnessgym/admin/admin_profile_screen.dart';
import 'package:afitnessgym/admin/admin_users.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class admin_home extends StatefulWidget {
  admin_home({super.key});

  @override
  State<admin_home> createState() => _admin_homeState();
}

class _admin_homeState extends State<admin_home> {
  @override
  int userCount = 0;
  int productCount = 0;
  int orderCount = 0;

  @override
  void initState() {
    super.initState();
    getUserCount();
    getProductCount();
    getOrderCount();
  }

  Future<void> getUserCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').count().get();

      setState(() {
        userCount = snapshot.count!;
      });
    } catch (e) {
      print("Error counting users: $e");
    }
  }

  Future<void> getProductCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('items').count().get();

      setState(() {
        productCount = snapshot.count!;
      });
    } catch (e) {
      print("Error counting products: $e");
    }
  }

  Future<void> getOrderCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('orders').count().get();

      setState(() {
        orderCount = snapshot.count!;
      });
    } catch (e) {
      print("Error counting orders: $e");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => admin_profile(),
              ), // Change to CheckoutScreen
            );
          },
          icon: Icon(Icons.person_2_outlined, size: 30, color: Colors.white),
        ),
        backgroundColor: Color(0xFF1F689F),
        title: Text(
          'WELCOME, ADMIN',
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      backgroundColor: Color(0xFF1F689F),
      body: Column(
        children: [
          SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 150,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Color(0xFF12476F),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        "Total Orders",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "$orderCount",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 150,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Color(0xFF12476F),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        "Total Products",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "$productCount",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: 150,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Color(0xFF12476F),
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  "Total Users",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text("$userCount", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 40),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const admin_orders()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF12476F), // Background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
            ),
            child: Text(
              'List of Orders >',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(height: 40),
          // Login Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const admin_products(),
                ), // Change to CheckoutScreen
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF12476F), // Background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
            ),
            child: Text(
              'List of Products >',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(height: 40),
          // Login Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Users(),
                ), // Change to CheckoutScreen
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF12476F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
            ),
            child: Text(
              'List of Users >',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
