import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/customer_type_filter.dart';
import 'widgets/customer_dialog.dart';
import 'widgets/customer_list.dart';

class CustomerMasterPage extends StatefulWidget {
  const CustomerMasterPage({super.key});

  @override
  State<CustomerMasterPage> createState() => _CustomerMasterPageState();
}

class _CustomerMasterPageState extends State<CustomerMasterPage> {
  List<DocumentSnapshot> customerTypes = [];
  String selectedCustomerType = '';

  @override
  void initState() {
    super.initState();
    fetchCustomerTypes();
  }

  Future<void> fetchCustomerTypes() async {
    final snap = await FirebaseFirestore.instance
        .collection('customer_types')
        .get();
    setState(() {
      customerTypes = snap.docs;
      selectedCustomerType = '';
    });
  }

  void showCustomerDialog(BuildContext context, {DocumentSnapshot? customer}) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomerDialog(
          customerTypes: customerTypes,
          customer: customer,
          initialCustomerType: selectedCustomerType,
          onSave: (name, tel, customerType, address1, kana) async {
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('名前を入力してください。'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (customer == null) {
              await FirebaseFirestore.instance.collection('customers').add({
                'name': name,
                'tel': tel,
                'customer_type': customerType,
                'address1': address1,
                'kana': kana,
                'createdAt': FieldValue.serverTimestamp(),
              });
            } else {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(customer.id)
                  .update({
                    'name': name,
                    'tel': tel,
                    'customer_type': customerType,
                    'address1': address1,
                    'kana': kana,
                  });
            }
          },
          onDelete: customer == null
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('削除の確認'),
                      content: const Text('本当にこの顧客を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            '削除',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(customer.id)
                        .delete();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('顧客管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomerTypeFilter(
              customerTypes: customerTypes,
              selectedCustomerType: selectedCustomerType,
              onChanged: (value) {
                setState(() {
                  selectedCustomerType = value;
                });
              },
            ),
          ),
          Expanded(
            child: CustomerList(
              customerTypes: customerTypes,
              selectedCustomerType: selectedCustomerType,
              onEdit: (customer) =>
                  showCustomerDialog(context, customer: customer),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomerDialog(context),
        tooltip: '顧客追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
