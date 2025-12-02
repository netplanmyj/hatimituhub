import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'widgets/product_selector.dart';

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
  List<DocumentSnapshot> productTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    debugPrint('📦 注文入力: 初期データ取得開始');

    final customerSnap = await FirestoreService.getCollectionSafely(
      'customers',
    );
    final productSnap = await FirestoreService.getCollectionSafely('products');
    final productTypeSnap = await FirestoreService.getCollectionSafely(
      'product_types',
    );

    if (customerSnap == null ||
        productSnap == null ||
        productTypeSnap == null) {
      // 認証エラーまたは取得エラー
      debugPrint('❌ 注文入力: データ取得失敗');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('データの取得に失敗しました。ログインしているか確認してください。'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    debugPrint('✅ 注文入力: データ取得成功');

    // デバッグ: 商品データの構造を確認
    if (productSnap.docs.isNotEmpty) {
      final firstProduct = productSnap.docs.first;
      debugPrint('🔍 商品データ構造: ${firstProduct.data()}');
    }

    setState(() {
      customers = customerSnap.docs;
      products = productSnap.docs;
      productTypes = productTypeSnap.docs;
      isLoading = false;
      if (customers.isNotEmpty) {
        selectedCustomerId = customers.first.id;
      }
      if (orderItems.isEmpty && products.isNotEmpty) {
        final firstProduct = products.first;
        final data = firstProduct.data() as Map<String, dynamic>;
        orderItems.add({
          'productId': firstProduct.id,
          'quantity': 1,
          'typeId': data.containsKey('type') ? data['type']?.toString() : null,
        });
      }
    });
  }

  void addOrderItem() {
    setState(() {
      final firstProduct = products.isNotEmpty ? products.first : null;
      final data = firstProduct?.data() as Map<String, dynamic>?;
      String? typeId;
      if (data != null && data.containsKey('type')) {
        typeId = data['type']?.toString();
      }
      orderItems.add({
        'productId': firstProduct?.id,
        'quantity': 1,
        'typeId': typeId,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (customers.isEmpty || products.isEmpty || productTypes.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'マスタデータが登録されていません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customers.isEmpty ? '• 顧客マスタ\n' : '',
                      style: const TextStyle(color: Colors.red),
                    ),
                    Text(
                      products.isEmpty ? '• 商品マスタ\n' : '',
                      style: const TextStyle(color: Colors.red),
                    ),
                    Text(
                      productTypes.isEmpty ? '• 商品区分マスタ\n' : '',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '先にマスタ登録を完了してください。',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                        final quantity = item['quantity'] as int? ?? 1;
                        final typeId =
                            item['typeId'] as String? ??
                            products.first['type']?.toString();
                        final productId =
                            item['productId'] as String? ?? products.first.id;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ProductSelector(
                              productTypes: productTypes,
                              products: products,
                              initialTypeId: typeId,
                              initialProductId: productId,
                              initialQuantity: quantity,
                              onChanged:
                                  (newTypeId, newProductId, newQuantity) {
                                    setState(() {
                                      orderItems[index]['typeId'] = newTypeId;
                                      orderItems[index]['productId'] =
                                          newProductId;
                                      orderItems[index]['quantity'] =
                                          newQuantity;
                                    });
                                  },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
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
                                final ordersCollection =
                                    FirestoreService.orders;
                                if (ordersCollection == null) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('認証エラーが発生しました'),
                                    ),
                                  );
                                  return;
                                }

                                final orderRef = await ordersCollection.add({
                                  'customerId': selectedCustomerId,
                                  'orderDate': Timestamp.fromDate(orderDate),
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

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
                                Navigator.of(context).pop(true);
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

  // (removed duplicated code)
}
