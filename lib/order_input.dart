import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderInputPage extends StatefulWidget {
  const OrderInputPage({super.key});

  @override
  State<OrderInputPage> createState() => _OrderInputPageState();
}

class _OrderInputPageState extends State<OrderInputPage> {
  String? selectedCustomerId;
  DateTime orderDate = DateTime.now();
  List<Map<String, dynamic>> orderItems = [];

  List<DocumentSnapshot> customers = [];
  List<DocumentSnapshot> products = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    final customerSnap = await FirebaseFirestore.instance
        .collection('customers')
        .get();
    final productSnap = await FirebaseFirestore.instance
        .collection('products')
        .get();
    setState(() {
      customers = customerSnap.docs;
      products = productSnap.docs;
      if (customers.isNotEmpty) {
        selectedCustomerId = customers.first.id;
      }
      if (orderItems.isEmpty && products.isNotEmpty) {
        orderItems.add({'productId': products.first.id, 'quantity': 1});
      }
    });
  }

  void addOrderItem() {
    setState(() {
      orderItems.add({
        'productId': products.isNotEmpty ? products.first.id : null,
        'quantity': 1,
      });
    });
  }

  void removeOrderItem(int index) {
    setState(() {
      orderItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注文入力')),
      body: customers.isEmpty || products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顧客選択
                  const Text('顧客'),
                  DropdownButton<String>(
                    value: selectedCustomerId,
                    items: customers.map((doc) {
                      final name = doc['name'] ?? '';
                      return DropdownMenuItem(value: doc.id, child: Text(name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCustomerId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // 注文日
                  Row(
                    children: [
                      const Text('注文日: '),
                      Text(
                        '${orderDate.year}/${orderDate.month}/${orderDate.day}',
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: orderDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              orderDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 注文明細
                  const Text('注文明細'),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        return Row(
                          children: [
                            // 商品選択
                            DropdownButton<String>(
                              value: item['productId'],
                              items: products.map((doc) {
                                final name = doc['name'] ?? '';
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  orderItems[index]['productId'] = value;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // 数量入力
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                initialValue: item['quantity'].toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '数量',
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    orderItems[index]['quantity'] =
                                        int.tryParse(val) ?? 1;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => removeOrderItem(index),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: addOrderItem,
                    child: const Text('明細追加'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedCustomerId == null || orderItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('顧客と明細を入力してください')),
                        );
                        return;
                      }
                      try {
                        // 注文データをordersコレクションに追加
                        final orderRef = await FirebaseFirestore.instance
                            .collection('orders')
                            .add({
                              'customerId': selectedCustomerId,
                              'orderDate': Timestamp.fromDate(orderDate),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        // 注文明細をorderItemsサブコレクションに追加
                        final batch = FirebaseFirestore.instance.batch();
                        for (var item in orderItems) {
                          batch.set(orderRef.collection('orderItems').doc(), {
                            'productId': item['productId'],
                            'quantity': item['quantity'],
                          });
                        }
                        await batch.commit();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('注文データを保存しました')),
                        );
                        // 入力内容を初期化
                        setState(() {
                          selectedCustomerId = customers.isNotEmpty
                              ? customers.first.id
                              : null;
                          orderDate = DateTime.now();
                          orderItems = products.isNotEmpty
                              ? [
                                  {
                                    'productId': products.first.id,
                                    'quantity': 1,
                                  },
                                ]
                              : [];
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('保存に失敗しました: ' + e.toString())),
                        );
                      }
                    },
                    child: const Text('注文追加'),
                  ),
                ],
              ),
            ),
    );
  }
}
