import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/product_item.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

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
                  final typeLabel = typeMap[typeId] ?? '未設定';
                  return ProductItem(
                    product: product,
                    typeLabel: typeLabel,
                    onEdit: () {
                      // 実装例: showProductDialog(context, product: product);
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 実装例: showProductDialog(context);
        },
        tooltip: '商品追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
