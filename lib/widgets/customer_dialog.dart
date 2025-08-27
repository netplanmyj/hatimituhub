import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerDialog extends StatefulWidget {
  final List<DocumentSnapshot> customerTypes;
  final DocumentSnapshot? customer;
  final String initialCustomerType;
  final void Function(
    String name,
    String tel,
    String customerType,
    String address1,
    String kana,
  )
  onSave;
  final void Function()? onDelete;

  const CustomerDialog({
    super.key,
    required this.customerTypes,
    required this.initialCustomerType,
    required this.onSave,
    this.customer,
    this.onDelete,
  });

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  late TextEditingController nameController;
  late TextEditingController telController;
  late TextEditingController address1Controller;
  late TextEditingController kanaController;
  late String dialogCustomerType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.customer?['name'] ?? '',
    );
    telController = TextEditingController(
      text:
          (widget.customer?.data() as Map<String, dynamic>?)?['tel']
              ?.toString() ??
          '',
    );
    address1Controller = TextEditingController(
      text:
          (widget.customer?.data() as Map<String, dynamic>?)?['address1']
              ?.toString() ??
          '',
    );
    kanaController = TextEditingController(
      text:
          (widget.customer?.data() as Map<String, dynamic>?)?['kana']
              ?.toString() ??
          '',
    );
    dialogCustomerType =
        widget.customer?['customer_type'] ?? widget.initialCustomerType;
  }

  @override
  Widget build(BuildContext context) {
    final dropdownItems = widget.customerTypes.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final label = data['typeLabel'] ?? doc.id;
      return DropdownMenuItem(value: doc.id, child: Text(label));
    }).toList();
    final validValues = dropdownItems.map((item) => item.value).toList();
    final dropdownValue =
        validValues.contains(dialogCustomerType) &&
            dialogCustomerType.isNotEmpty
        ? dialogCustomerType
        : null;

    return AlertDialog(
      title: Text(widget.customer == null ? '顧客追加' : '顧客編集'),
      content: Column(
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
            value: dropdownValue,
            items: dropdownItems,
            hint: const Text('区分を選択'),
            onChanged: (value) {
              setState(() {
                dialogCustomerType = value ?? widget.initialCustomerType;
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
