import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      if (customerTypes.isNotEmpty) {
        selectedCustomerType = customerTypes.first.id;
      }
    });
  }

  void showCustomerDialog(BuildContext context, {DocumentSnapshot? customer}) {
    final nameController = TextEditingController(text: customer?['name'] ?? '');
    final telController = TextEditingController(
      text:
          (customer?.data() as Map<String, dynamic>?)?['tel']?.toString() ?? '',
    );
    String dialogCustomerType =
        customer?['customer_type'] ?? selectedCustomerType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(customer == null ? '顧客追加' : '顧客編集'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '顧客名'),
                  ),
                  TextField(
                    controller: telController,
                    decoration: const InputDecoration(labelText: '電話番号'),
                    keyboardType: TextInputType.phone,
                  ),
                  DropdownButton<String>(
                    value: dialogCustomerType,
                    items: customerTypes.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final label = data['typeLabel'] ?? doc.id;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        dialogCustomerType = value ?? selectedCustomerType;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                if (customer != null)
                  TextButton(
                    onPressed: () async {
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
                    child: const Text(
                      '削除',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final tel = telController.text.trim();
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
                      await FirebaseFirestore.instance
                          .collection('customers')
                          .add({
                            'name': name,
                            'tel': tel,
                            'customer_type': dialogCustomerType,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    } else {
                      await FirebaseFirestore.instance
                          .collection('customers')
                          .doc(customer.id)
                          .update({
                            'name': name,
                            'tel': tel,
                            'customer_type': dialogCustomerType,
                          });
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(customer == null ? '追加' : '更新'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('顧客管理')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final customers = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final data = customer.data() as Map<String, dynamic>;
              String typeLabel = '';
              DocumentSnapshot? typeDoc;
              if (customerTypes.isNotEmpty) {
                try {
                  typeDoc = customerTypes.firstWhere(
                    (doc) => doc.id == data['customer_type'],
                  );
                } catch (e) {
                  typeDoc = null;
                }
                if (typeDoc != null) {
                  final typeData = typeDoc.data() as Map<String, dynamic>;
                  typeLabel = typeData['typeLabel'] ?? '';
                }
              }
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(
                  '${data.containsKey('tel') ? data['tel'] : ''}'
                  '${typeLabel.isNotEmpty ? ' / $typeLabel' : ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      showCustomerDialog(context, customer: customer),
                ),
              );
            },
            // ...existing code...
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomerDialog(context),
        tooltip: '顧客追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
