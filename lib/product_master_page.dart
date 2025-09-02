import 'widgets/product_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductMasterPage extends StatelessWidget {
  const ProductMasterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final teamId = user?.uid ?? 'unknown_team';
    return Scaffold(
      appBar: AppBar(title: const Text('商品管理')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('team_data')
            .doc(teamId)
            .collection('product_types')
            .get(),
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
                .collection('team_data')
                .doc(teamId)
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
                          ProductDialog.show(context, product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ProductDialog.show(context),
        tooltip: '商品追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
