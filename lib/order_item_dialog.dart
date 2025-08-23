import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:honeysales/widgets/quantity_input.dart';

Future<void> orderItemEditDialog(
  BuildContext context,
  String orderId,
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
                QuantityInput(
                  quantity: selectedQuantity,
                  onChanged: (val) {
                    setState(() {
                      selectedQuantity = val;
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
                      .doc(itemId)
                      .delete();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () async {
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

Future<void> orderItemAddDialog(BuildContext context, String orderId) async {
  final productsSnap = await FirebaseFirestore.instance
      .collection('products')
      .get();
  final products = productsSnap.docs;
  if (products.isEmpty) return;

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
                QuantityInput(
                  quantity: selectedQuantity,
                  onChanged: (val) {
                    setState(() {
                      selectedQuantity = val;
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
