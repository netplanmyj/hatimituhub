import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDialog {
  static void show(BuildContext context, {DocumentSnapshot? product}) {
    final user = FirebaseAuth.instance.currentUser;
    final teamId = user?.uid ?? 'unknown_team';
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('team_data')
              .doc(teamId)
              .collection('product_types')
              .get(),
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
                        .collection('team_data')
                        .doc(teamId)
                        .collection('products')
                        .add({
                          'name': name,
                          'price': price,
                          'type': typeId,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('team_data')
                        .doc(teamId)
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
                            .collection('team_data')
                            .doc(teamId)
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
}
