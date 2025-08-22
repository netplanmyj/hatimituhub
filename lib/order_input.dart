import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/quantity_input.dart';

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
                  Row(
                    children: [
                      // 顧客選択
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedCustomerId,
                          items: customers.map((doc) {
                            final name = doc['name'] ?? '';
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCustomerId = value;
                            });
                          },
                        ),
                      ),
                      // 注文日（ラベル省略、右側に年月日表示）
                      Text(
                        '${orderDate.year}/${orderDate.month}/${orderDate.day}',
                        style: const TextStyle(fontSize: 16),
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

                  Expanded(
                    child: ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final orientation = MediaQuery.of(context).orientation;
                        final quantity = item['quantity'] as int? ?? 1;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: orientation == Orientation.portrait
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 商品名
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
                                            orderItems[index]['productId'] =
                                                value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // 数量入力ウィジェット（分離版）
                                      QuantityInput(
                                        quantity: quantity,
                                        onChanged: (newQuantity) {
                                          setState(() {
                                            orderItems[index]['quantity'] =
                                                newQuantity;
                                          });
                                        },
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () =>
                                              removeOrderItem(index),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      // 商品名
                                      Expanded(
                                        child: DropdownButton<String>(
                                          value: item['productId'],
                                          isExpanded: true,
                                          items: products.map((doc) {
                                            final name = doc['name'] ?? '';
                                            return DropdownMenuItem(
                                              value: doc.id,
                                              child: Text(name),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              orderItems[index]['productId'] =
                                                  value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // 数量入力ウィジェット（分離版）
                                      QuantityInput(
                                        quantity: quantity,
                                        onChanged: (newQuantity) {
                                          setState(() {
                                            orderItems[index]['quantity'] =
                                                newQuantity;
                                          });
                                        },
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () => removeOrderItem(index),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  // ボタンを横並びに配置
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: addOrderItem,
                            child: const Text('明細追加'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedCustomerId == null ||
                                  orderItems.isEmpty) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('顧客と明細を入力してください'),
                                  ),
                                );
                                return;
                              }
                              try {
                                // 注文データをordersコレクションに追加
                                final orderRef = await FirebaseFirestore
                                    .instance
                                    .collection('orders')
                                    .add({
                                      'customerId': selectedCustomerId,
                                      'orderDate': Timestamp.fromDate(
                                        orderDate,
                                      ),
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                // 注文明細をorderItemsサブコレクションに追加
                                final batch = FirebaseFirestore.instance
                                    .batch();
                                for (var item in orderItems) {
                                  batch.set(
                                    orderRef.collection('orderItems').doc(),
                                    {
                                      'productId': item['productId'],
                                      'quantity': item['quantity'],
                                    },
                                  );
                                }
                                await batch.commit();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('注文データを保存しました')),
                                );
                                // 入力内容の初期化は削除
                                // 注文一覧画面に戻る
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('保存に失敗しました: ${e.toString()}'),
                                  ),
                                );
                              }
                            },
                            child: const Text('注文保存'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
