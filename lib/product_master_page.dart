import 'widgets/product_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductMasterPage extends StatelessWidget {
  const ProductMasterPage({super.key});

  void showProductDialog(BuildContext context, {DocumentSnapshot? product}) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('product_types').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final types = snapshot.data!.docs;
            return AlertDialog(
              title: Text(product == null ? '商品追加' : '商品編集'),
              content: ProductItemForm(
                product: product,
                types: types,
                onSave: (name, price, typeId) async {
                  if (product == null) {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .add({
                          'name': name,
                          'price': price,
                          'type': typeId,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(product.id)
                        .update({'name': name, 'price': price, 'type': typeId});
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                onDelete: product == null
                    ? null
                    : () async {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(product.id)
                            .delete();
                        if (context.mounted) Navigator.of(context).pop();
                      },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品管理')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('product_types').get(),
        builder: (context, typeSnapshot) {
          if (!typeSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final typeDocs = typeSnapshot.data!.docs;
          final typeMap = {
            for (var doc in typeDocs)
              doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? doc.id,
          };
          return StreamBuilder<QuerySnapshot>(
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
                  final typeId = data['type']?.toString();
                  final typeLabel = typeMap[typeId];
                  return ListTile(
                    title: Text(data['name'] ?? ''),
                    subtitle: Text(
                      '${data['price'] != null ? '¥${data['price']}' : ''}  区分: ${typeLabel ?? '未設定'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          showProductDialog(context, product: product),
                    ),
                  );
                },
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
