import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'services/invoice_service.dart';
import 'package:hatimituhub/widgets/order_item_dialog.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注文内容'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateInvoicePdf(context),
            tooltip: '請求書PDF作成',
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: FirestoreService.getDocumentSafely('orders', orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<DocumentSnapshot?>(
                          future: FirestoreService.getDocumentSafely(
                            'customers',
                            customerId,
                          ),
                          builder: (context, customerSnap) {
                            String customerName = customerId;
                            if (customerSnap.hasData &&
                                customerSnap.data != null &&
                                customerSnap.data!.exists) {
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
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: '注文削除',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('注文削除の確認'),
                            content: const Text('この注文を削除しますか？'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  '削除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final orderDoc = FirestoreService.getTeamDocument(
                            'orders',
                            orderId,
                          );
                          if (orderDoc != null) {
                            await orderDoc.delete();
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('注文明細'),
                    ElevatedButton(
                      onPressed: () => orderItemAddDialog(context, orderId),
                      child: const Text('明細追加'),
                    ),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirestoreService.getOrderItems(
                      orderId,
                    )?.snapshots(),
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
                          return FutureBuilder<DocumentSnapshot?>(
                            future: FirestoreService.getDocumentSafely(
                              'products',
                              productId,
                            ),
                            builder: (context, prodSnap) {
                              String productName = productId;
                              int price = 0;
                              if (prodSnap.hasData &&
                                  prodSnap.data != null &&
                                  prodSnap.data!.exists) {
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
                                        orderItemEditDialog(
                                          context,
                                          orderId,
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
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: '明細削除',
                                      onPressed: () async {
                                        final orderItemsRef =
                                            FirestoreService.getOrderItems(
                                              orderId,
                                            );
                                        if (orderItemsRef != null) {
                                          await orderItemsRef
                                              .doc(items[idx].id)
                                              .delete();
                                        }
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

  /// 請求書PDF生成
  Future<void> _generateInvoicePdf(BuildContext context) async {
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
            content: Text('請求書の生成に失敗しました。請求者情報が登録されているか確認してください。'),
            backgroundColor: Colors.red,
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
