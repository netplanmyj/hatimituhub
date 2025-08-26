import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductItemForm extends StatefulWidget {
  final DocumentSnapshot? product;
  final List<QueryDocumentSnapshot> types;
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?['name'] ?? '');
    priceController = TextEditingController(
      text: widget.product?['price']?.toString() ?? '',
    );
    final typeId = widget.product?['type']?.toString();
    final availableTypeIds = widget.types.map((typeDoc) => typeDoc.id).toSet();
    selectedTypeId = (typeId != null && availableTypeIds.contains(typeId)) ? typeId : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '商品名'),
        ),
        TextField(
          controller: priceController,
          decoration: const InputDecoration(labelText: '価格'),
          keyboardType: TextInputType.number,
        ),
        DropdownButtonFormField<String>(
          initialValue: selectedTypeId,
          decoration: const InputDecoration(labelText: '商品区分'),
          items: widget.types.map((typeDoc) {
            final typeData = typeDoc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: typeDoc.id,
              child: Text(typeData['name'] ?? typeDoc.id),
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
            if (widget.product != null && widget.onDelete != null)
              TextButton(
                onPressed: widget.onDelete,
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = int.tryParse(priceController.text.trim()) ?? 0;
                if (name.isEmpty || selectedTypeId == null) return;
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
