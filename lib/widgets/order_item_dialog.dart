import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:honeysales/widgets/product_selector.dart';

class OrderItemDialog extends StatefulWidget {
  final List<DocumentSnapshot> products;
  final List<DocumentSnapshot> productTypes;
  final String? initialProductId;
  final String? initialTypeId;
  final int initialQuantity;
  final String title;
  final void Function(String productId, int quantity, String? typeId) onSave;
  final void Function()? onDelete;

  const OrderItemDialog({
    super.key,
    required this.products,
    required this.productTypes,
    required this.title,
    required this.onSave,
    this.onDelete,
    this.initialProductId,
    this.initialTypeId,
    this.initialQuantity = 1,
  });

  @override
  State<OrderItemDialog> createState() => _OrderItemDialogState();
}

class _OrderItemDialogState extends State<OrderItemDialog> {
  late String selectedProductId;
  late String selectedTypeId;
  late int selectedQuantity;

  @override
  void initState() {
    super.initState();
    selectedProductId =
        widget.initialProductId ??
        (widget.products.isNotEmpty ? widget.products.first.id : '');
    selectedTypeId =
        widget.initialTypeId ??
        (widget.products.isNotEmpty
            ? widget.products.first['type']?.toString() ?? ''
            : '');
    selectedQuantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProductSelector(
            productTypes: widget.productTypes,
            products: widget.products,
            initialTypeId: selectedTypeId,
            initialProductId: selectedProductId,
            initialQuantity: selectedQuantity,
            onChanged: (typeId, productId, quantity) {
              setState(() {
                selectedTypeId = typeId;
                selectedProductId = productId;
                selectedQuantity = quantity;
              });
            },
          ),
        ],
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () {
            widget.onSave(selectedProductId, selectedQuantity, selectedTypeId);
            Navigator.of(context).pop();
          },
          child: Text(widget.onDelete != null ? '保存' : '追加'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}

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
  final productTypesSnap = await FirebaseFirestore.instance
      .collection('product_types')
      .get();
  final products = productsSnap.docs;
  final productTypes = productTypesSnap.docs;
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) {
      return OrderItemDialog(
        products: products,
        productTypes: productTypes,
        initialProductId: productId,
        initialTypeId: products
            .firstWhere((p) => p.id == productId)['type']
            ?.toString(),
        initialQuantity: quantity,
        title: '明細編集',
        onSave: (selectedProductId, selectedQuantity, selectedTypeId) async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .collection('orderItems')
              .doc(itemId)
              .update({
                'productId': selectedProductId,
                'quantity': selectedQuantity,
              });
        },
        onDelete: () async {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .collection('orderItems')
              .doc(itemId)
              .delete();
          if (context.mounted) Navigator.of(context).pop();
        },
      );
    },
  );
}

Future<void> orderItemAddDialog(BuildContext context, String orderId) async {
  final productsSnap = await FirestoreService.getCollectionSafely('products');
  final productTypesSnap = await FirestoreService.getCollectionSafely(
    'product_types',
  );

  if (productsSnap == null || productTypesSnap == null) return;

  final products = productsSnap.docs;
  final productTypes = productTypesSnap.docs;
  if (products.isEmpty || !context.mounted) return;

  showDialog(
    context: context,
    builder: (context) {
      return OrderItemDialog(
        products: products,
        productTypes: productTypes,
        initialProductId: products.first.id,
        initialTypeId: products.first['type']?.toString(),
        initialQuantity: 1,
        title: '明細追加',
        onSave: (selectedProductId, selectedQuantity, selectedTypeId) async {
          final orderItemsRef = FirestoreService.getOrderItems(orderId);
          if (orderItemsRef != null) {
            await orderItemsRef.add({
              'productId': selectedProductId,
              'quantity': selectedQuantity,
            });
          }
        },
      );
    },
  );
}
