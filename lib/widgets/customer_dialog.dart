import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerDialog extends StatefulWidget {
  final List<DocumentSnapshot> customerTypes;
  final DocumentSnapshot? customer;
  final String initialCustomerType;
  final Function(
    String name,
    String tel,
    String customerType,
    String address1,
    String kana,
  )
  onSave;
  final Future<void> Function()? onDelete;

  const CustomerDialog({
    super.key,
    required this.customerTypes,
    required this.customer,
    required this.initialCustomerType,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  late TextEditingController nameController;
  late TextEditingController kanaController;
  late TextEditingController address1Controller;
  late TextEditingController telController;
  late String dialogCustomerType;

  @override
  void initState() {
    super.initState();
    final data = widget.customer?.data() as Map<String, dynamic>? ?? {};
    nameController = TextEditingController(text: data['name'] ?? '');
    kanaController = TextEditingController(
      text: data['kana']?.toString() ?? '',
    );
    address1Controller = TextEditingController(
      text: data['address1']?.toString() ?? '',
    );
    telController = TextEditingController(text: data['tel']?.toString() ?? '');
    dialogCustomerType = data['customer_type'] ?? widget.initialCustomerType;
  }

  @override
  void dispose() {
    nameController.dispose();
    kanaController.dispose();
    address1Controller.dispose();
    telController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedTypes = [...widget.customerTypes];
    sortedTypes.sort((a, b) {
      final aOrder = (a.data() as Map<String, dynamic>)['displayOrder'] ?? 0;
      final bOrder = (b.data() as Map<String, dynamic>)['displayOrder'] ?? 0;
      return aOrder.compareTo(bOrder);
    });
    return AlertDialog(
      title: Text(widget.customer == null ? '顧客追加' : '顧客編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '顧客名'),
            ),
            TextField(
              controller: kanaController,
              decoration: const InputDecoration(labelText: 'フリガナ'),
            ),
            TextField(
              controller: address1Controller,
              decoration: const InputDecoration(labelText: '住所1'),
            ),
            TextField(
              controller: telController,
              decoration: const InputDecoration(labelText: '電話番号'),
              keyboardType: TextInputType.phone,
            ),
            DropdownButton<String>(
              value: dialogCustomerType.isEmpty ? null : dialogCustomerType,
              items: [
                ...sortedTypes.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final label = data['name'] ?? doc.id;
                  return DropdownMenuItem(value: doc.id, child: Text(label));
                }),
              ],
              hint: const Text('区分を選択'),
              onChanged: (value) {
                setState(() {
                  dialogCustomerType = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () {
            final name = nameController.text.trim();
            final tel = telController.text.trim();
            final address1 = address1Controller.text.trim();
            final kana = kanaController.text.trim();
            widget.onSave(name, tel, dialogCustomerType, address1, kana);
            Navigator.of(context).pop();
          },
          child: Text(widget.customer == null ? '追加' : '更新'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
