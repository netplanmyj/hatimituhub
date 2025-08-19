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

  void showEditDialog(
    BuildContext context,
    String itemId,
    String productId,
    int quantity,
  ) async {
    final productsSnap = await FirebaseFirestore.instance
        .collection('products')
        .get();
    final products = productsSnap.docs;
    String selectedProductId = productId;
    int selectedQuantity = quantity;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('明細編集'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedProductId,
                    items: products.map((doc) {
                      final name = doc['name'] ?? '';
                      return DropdownMenuItem(value: doc.id, child: Text(name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProductId = value ?? productId;
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: selectedQuantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '数量'),
                    onChanged: (val) {
                      setState(() {
                        selectedQuantity = int.tryParse(val) ?? quantity;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // 明細削除
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .collection('orderItems')
                        .doc(itemId)
                        .delete();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('削除', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    // 明細更新
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .collection('orderItems')
                        .doc(itemId)
                        .update({
                          'productId': selectedProductId,
                          'quantity': selectedQuantity,
                        });
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showAddDialog(BuildContext context) async {
    final productsSnap = await FirebaseFirestore.instance
        .collection('products')
        .get();
    final products = productsSnap.docs;
    if (products.isEmpty) return;
    // async後のcontext利用前に必ずガード
    if (!context.mounted) return;

    String selectedProductId = products.first.id;
    int selectedQuantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('明細追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedProductId,
                    items: products.map((doc) {
                      final name = doc['name'] ?? '';
                      return DropdownMenuItem(value: doc.id, child: Text(name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProductId = value ?? products.first.id;
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: selectedQuantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '数量'),
                    onChanged: (val) {
                      setState(() {
                        selectedQuantity = int.tryParse(val) ?? 1;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .collection('orderItems')
                        .add({
                          'productId': selectedProductId,
                          'quantity': selectedQuantity,
                        });
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('追加'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('注文明細'),
                    ElevatedButton(
                      onPressed: () => showAddDialog(context),
                      child: const Text('明細追加'),
                    ),
                  ],
                ),
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
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        showEditDialog(
                                          context,
                                          items[idx].id,
                                          productId,
                                          quantity is int
                                              ? quantity
                                              : int.tryParse(
                                                      quantity.toString(),
                                                    ) ??
                                                    0,
                                        );
                                      },
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
