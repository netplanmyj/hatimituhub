import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductMasterPage extends StatelessWidget {
  const ProductMasterPage({super.key});

  void showProductDialog(BuildContext context, {DocumentSnapshot? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? '商品追加' : '商品編集'),
          content: Column(
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
            ],
          ),
          actions: [
            if (product != null)
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(product.id)
                      .delete();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('削除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = int.tryParse(priceController.text.trim()) ?? 0;
                if (name.isEmpty) return;
                if (product == null) {
                  await FirebaseFirestore.instance.collection('products').add({
                    'name': name,
                    'price': price,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(product.id)
                      .update({'name': name, 'price': price});
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(product == null ? '追加' : '更新'),
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
      appBar: AppBar(title: const Text('商品管理')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final data = product.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(
                  data['price'] != null ? '¥${data['price']}' : '',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => showProductDialog(context, product: product),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(context),
        tooltip: '商品追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
