import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_master_page.dart';
import 'order_detail_page.dart';
import 'order_input.dart';
import 'product_master_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  static const int pageSize = 10;
  List<DocumentSnapshot> orders = [];
  DocumentSnapshot? lastDocument;
  int currentPage = 0;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchOrders(reset: true);
  }

  Future<void> fetchOrders({bool reset = false}) async {
    setState(() {
      isLoading = true;
    });
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (!reset && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }
    final snapshot = await query.get();
    orders = snapshot.docs;
    if (reset) {
      currentPage = 0;
    } else {
      currentPage++;
    }
    lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : lastDocument;
    hasMore = snapshot.docs.length == pageSize;
    setState(() {
      isLoading = false;
    });
  }

  void goToNextPage() {
    if (hasMore && !isLoading) {
      fetchOrders();
    }
  }

  void goToPrevPage() {
    if (currentPage > 0 && !isLoading) {
      // 前ページの最後のドキュメントを取得
      int prevPage = currentPage - 1;
      Query query = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (prevPage > 0 && orders.isNotEmpty) {
        query = query.startAfterDocument(orders.first);
      }
      fetchOrders(reset: true);
      currentPage = prevPage;
    }
  }

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text('注文データがありません'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final data = order.data() as Map<String, dynamic>;
                      final customerId = data['customerId'] ?? '';
                      final orderDate = (data['orderDate'] as Timestamp?)
                          ?.toDate();
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('customers')
                            .doc(customerId)
                            .get(),
                        builder: (context, customerSnap) {
                          String customerName = customerId;
                          if (customerSnap.hasData &&
                              customerSnap.data!.exists) {
                            customerName =
                                customerSnap.data!.get('name') ?? customerId;
                          }
                          return ListTile(
                            title: Text(customerName),
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
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: currentPage > 0 ? goToPrevPage : null,
                      child: const Text('前へ'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: hasMore ? goToNextPage : null,
                      child: const Text('次へ'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
