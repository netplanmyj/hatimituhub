import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_master_page.dart';
import 'order_detail_page.dart';
import 'order_input.dart';
import 'product_master_page.dart';

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注文一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: '注文入力',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OrderInputPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: '商品管理',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductMasterPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: '顧客管理',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerMasterPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('注文データがありません'));
          }
          final orders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              final customerId = data['customerId'] ?? '';
              final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('customers')
                    .doc(customerId)
                    .get(),
                builder: (context, customerSnap) {
                  String customerName = customerId;
                  if (customerSnap.hasData && customerSnap.data!.exists) {
                    customerName = customerSnap.data!.get('name') ?? customerId;
                  }
                  return ListTile(
                    title: Text('顧客: $customerName'),
                    subtitle: Text(
                      orderDate != null
                          ? '注文日: ${orderDate.year}/${orderDate.month}/${orderDate.day}'
                          : '',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailPage(orderId: order.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
