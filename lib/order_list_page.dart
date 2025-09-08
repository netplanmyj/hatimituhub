import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'services/invoice_service.dart';
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

    final ordersCollection = FirestoreService.orders;
    if (ordersCollection == null) {
      setState(() {
        isLoading = false;
        hasMore = false;
      });
      return;
    }

    Query query = ordersCollection
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
      final ordersCollection = FirestoreService.orders;
      if (ordersCollection == null) return;

      Query query = ordersCollection
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
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OrderInputPage()),
              );
              if (result == true) {
                fetchOrders(reset: true);
              }
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
                      return FutureBuilder<DocumentSnapshot?>(
                        future: customerId.isNotEmpty
                            ? FirestoreService.getDocumentSafely(
                                'customers',
                                customerId,
                              )
                            : Future.value(null),
                        builder: (context, customerSnap) {
                          String customerName = customerId;
                          if (customerSnap.hasData &&
                              customerSnap.data != null &&
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf),
                                  onPressed: () =>
                                      _generateInvoicePdf(context, order.id),
                                  tooltip: 'PDF作成',
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
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

  /// 請求書PDF生成
  Future<void> _generateInvoicePdf(BuildContext context, String orderId) async {
    // 早期に必要な値を保存
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // PDF生成・表示
      final success = await InvoiceService.generateAndPrintInvoice(orderId);

      // ローディング非表示
      navigator.pop();

      if (!success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('請求書の生成に失敗しました。\n設定メニューから請求者情報を登録してください。'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // ローディング非表示
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
