import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:hatimituhub/widgets/product_selector.dart';

class OrderItemDialog extends StatefulWidget {
  final List<DocumentSnapshot> products;
  final List<DocumentSnapshot> productTypes;
  final String? initialProductId;
  final String? initialTypeId;
  final int initialQuantity;
  final String title;
  final void Function(String productId, int quantity, String? typeId) onSave;
  // onDelete削除
  const OrderItemDialog({
    super.key,
    required this.products,
    required this.productTypes,
    required this.title,
    required this.onSave,
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
    // 型安全にid/type取得
    selectedProductId =
        widget.initialProductId ??
        (() {
          if (widget.products.isNotEmpty) {
            final first = widget.products.first;
            if (first is Map) {
              return first['id']?.toString() ?? '';
            } else {
              // DocumentSnapshot/QueryDocumentSnapshot
              try {
                return first.id.toString();
              } catch (_) {
                return '';
              }
            }
          }
          return '';
        })();
    selectedTypeId =
        widget.initialTypeId ??
        (() {
          if (widget.products.isNotEmpty) {
            final first = widget.products.first;
            if (first is Map) {
              return first['type']?.toString() ?? '';
            } else {
              try {
                final data = first.data() as Map<String, dynamic>?;
                return data != null && data['type'] != null
                    ? data['type'].toString()
                    : '';
              } catch (_) {
                return '';
              }
            }
          }
          return '';
        })();
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
        TextButton(
          onPressed: () {
            widget.onSave(selectedProductId, selectedQuantity, selectedTypeId);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
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
  final productsSnap = await FirestoreService.getCollectionSafely('products');
  final productTypesSnap = await FirestoreService.getCollectionSafely(
    'product_types',
  );
  if (productsSnap == null || productTypesSnap == null) return;
  final products = productsSnap.docs;
  final productTypes = productTypesSnap.docs;
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) {
      // 安全にtype取得
      String? initialTypeId;
      final found = products.cast<dynamic>().firstWhere(
        (p) => (p is Map ? p['id']?.toString() : p.id.toString()) == productId,
        orElse: () => null,
      );
      if (found is Map) {
        initialTypeId = found['type']?.toString();
      } else if (found != null) {
        try {
          final data = found.data() as Map<String, dynamic>?;
          initialTypeId = data != null && data['type'] != null
              ? data['type'].toString()
              : null;
        } catch (_) {
          initialTypeId = null;
        }
      } else {
        initialTypeId = null;
      }
      return OrderItemDialog(
        products: products,
        productTypes: productTypes,
        initialProductId: productId,
        initialTypeId: initialTypeId,
        initialQuantity: quantity,
        title: '明細編集',
        onSave: (selectedProductId, selectedQuantity, selectedTypeId) async {
          final orderItemsRef = FirestoreService.getOrderItems(orderId);
          if (orderItemsRef != null) {
            await orderItemsRef.doc(itemId).update({
              'productId': selectedProductId,
              'quantity': selectedQuantity,
            });
          }
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
