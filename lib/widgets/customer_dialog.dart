import 'package:flutter/material.dart';

class CustomerDialog extends StatefulWidget {
  final List<dynamic> customerTypes;
  final dynamic customer;
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
    final data = widget.customer is Map
        ? widget.customer as Map<String, dynamic>
        : (widget.customer?.data() as Map<String, dynamic>? ?? {});
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
      final aData = a is Map ? a : a.data() as Map<String, dynamic>;
      final bData = b is Map ? b : b.data() as Map<String, dynamic>;
      final aOrder = aData['displayOrder'] ?? 0;
      final bOrder = bData['displayOrder'] ?? 0;
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
                  final data = doc is Map
                      ? doc
                      : doc.data() as Map<String, dynamic>;
                  final id = doc is Map ? doc['id'] : doc.id;
                  final label = data['name'] ?? id;
                  return DropdownMenuItem(value: id, child: Text(label));
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
