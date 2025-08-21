import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerMasterPage extends StatelessWidget {
  const CustomerMasterPage({super.key});

  void showCustomerDialog(BuildContext context, {DocumentSnapshot? customer}) {
    final nameController = TextEditingController(text: customer?['name'] ?? '');
    final telController = TextEditingController(
      text:
          customer != null &&
              (customer.data() as Map<String, dynamic>).containsKey('tel')
          ? (customer.data() as Map<String, dynamic>)['tel']
      text: (customer?.data() as Map<String, dynamic>?)?['tel']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
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
            ],
          ),
          actions: [
            if (customer != null)
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('customers')
                      .doc(customer.id)
                      .delete();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('削除の確認'),
                      content: const Text('本当にこの顧客を削除しますか？この操作は元に戻せません。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('削除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(customer.id)
                        .delete();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final tel = telController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('顧客名を入力してください。'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (customer == null) {
                  await FirebaseFirestore.instance.collection('customers').add({
                    'name': name,
                    'tel': tel,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await FirebaseFirestore.instance
                      .collection('customers')
                      .doc(customer.id)
                      .update({'name': name, 'tel': tel});
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
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['tel'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      showCustomerDialog(context, customer: customer),
                ),
              );
            },
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
