import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductItemForm extends StatefulWidget {
  final dynamic product;
  final List<dynamic> types;
  final void Function(String name, int price, String typeId)? onSave;
  final void Function()? onDelete;

  const ProductItemForm({
    super.key,
    this.product,
    required this.types,
    this.onSave,
    this.onDelete,
  });

  @override
  State<ProductItemForm> createState() => _ProductItemFormState();
}

class _ProductItemFormState extends State<ProductItemForm> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  String? selectedTypeId;
  String? nameError;
  String? typeError;

  @override
  void initState() {
    super.initState();
    final productData = widget.product is Map
        ? widget.product as Map<String, dynamic>
        : (widget.product?.data() as Map<String, dynamic>? ?? {});
    nameController = TextEditingController(text: productData['name'] ?? '');
    priceController = TextEditingController(
      text: productData['price']?.toString() ?? '',
    );
    final typeId = productData['type']?.toString();
    final availableTypeIds = widget.types
        .map((typeDoc) => typeDoc is Map ? typeDoc['id'] : typeDoc.id)
        .toSet();
    selectedTypeId = (typeId != null && availableTypeIds.contains(typeId))
        ? typeId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: '商品名', errorText: nameError),
        ),
        TextField(
          controller: priceController,
          decoration: const InputDecoration(labelText: '価格'),
          keyboardType: TextInputType.number,
        ),
        DropdownButtonFormField<String>(
          initialValue: selectedTypeId,
          decoration: InputDecoration(labelText: '商品区分', errorText: typeError),
          items: widget.types.map((typeDoc) {
            final typeData = typeDoc is Map
                ? typeDoc
                : typeDoc.data() as Map<String, dynamic>;
            final id = typeDoc is Map ? typeDoc['id'] : typeDoc.id;
            return DropdownMenuItem<String>(
              value: id,
              child: Text(typeData['name'] ?? id),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTypeId = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = int.tryParse(priceController.text.trim()) ?? 0;
                bool hasError = false;
                setState(() {
                  if (name.isEmpty) {
                    nameError = '商品名は必須です';
                    hasError = true;
                  } else {
                    nameError = null;
                  }
                  if (selectedTypeId == null) {
                    typeError = '商品区分を選択してください';
                    hasError = true;
                  } else {
                    typeError = null;
                  }
                });
                if (hasError) return;
                widget.onSave?.call(name, price, selectedTypeId!);
              },
              child: Text(widget.product == null ? '追加' : '更新'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ],
    );
  }
}

class ProductItem extends StatelessWidget {
  final DocumentSnapshot product;
  final String? typeLabel;
  final VoidCallback? onEdit;

  const ProductItem({
    super.key,
    required this.product,
    required this.typeLabel,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final data = product.data() as Map<String, dynamic>;
    return ListTile(
      title: Text(data['name'] ?? ''),
      subtitle: Text(
        '${data['price'] != null ? '¥${data['price']}' : ''}  区分: ${typeLabel ?? '未設定'}',
      ),
      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
    );
  }
}
