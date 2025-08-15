import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注文一覧')),
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

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注文詳細')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('注文データがありません'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final customerId = data['customerId'] ?? '';
          final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('customers')
                      .doc(customerId)
                      .get(),
                  builder: (context, customerSnap) {
                    String customerName = customerId;
                    if (customerSnap.hasData && customerSnap.data!.exists) {
                      customerName =
                          customerSnap.data!.get('name') ?? customerId;
                    }
                    return Text('顧客: $customerName');
                  },
                ),
                Text(
                  orderDate != null
                      ? '注文日: ${orderDate.year}/${orderDate.month}/${orderDate.day}'
                      : '',
                ),
                const SizedBox(height: 16),
                const Text('注文明細'),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .collection('orderItems')
                        .snapshots(),
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!itemSnapshot.hasData ||
                          itemSnapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('明細がありません'));
                      }
                      final items = itemSnapshot.data!.docs;
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item =
                              items[idx].data() as Map<String, dynamic>;
                          final productId = item['productId'] ?? '';
                          final quantity = item['quantity'] ?? 0;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('products')
                                .doc(productId)
                                .get(),
                            builder: (context, prodSnap) {
                              String productName = productId;
                              int price = 0;
                              if (prodSnap.hasData && prodSnap.data!.exists) {
                                final prodData =
                                    prodSnap.data!.data()
                                        as Map<String, dynamic>;
                                productName = prodData['name'] ?? productId;
                                price = prodData['price'] ?? 0;
                              }
                              final total =
                                  price *
                                  (quantity is int
                                      ? quantity
                                      : int.tryParse(quantity.toString()) ?? 0);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '商品: $productName',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      '数量: $quantity',
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '¥$total',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
