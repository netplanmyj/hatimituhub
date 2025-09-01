import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductCategoryMasterPage extends StatefulWidget {
  const ProductCategoryMasterPage({super.key});

  @override
  State<ProductCategoryMasterPage> createState() =>
      _ProductCategoryMasterPageState();
}

class _ProductCategoryMasterPageState extends State<ProductCategoryMasterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  List<DocumentSnapshot> productCategories = [];

  @override
  void initState() {
    super.initState();
    fetchProductCategories();
  }

  Future<void> fetchProductCategories() async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('product_categories')
        .orderBy('displayOrder')
        .get();
    setState(() {
      productCategories = snapshot.docs;
    });
  }

  Future<void> addProductCategory(String name, int displayOrder) async {
    if (name.isEmpty) return;
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    // 重複チェック
    final dup = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('product_categories')
        .where('name', isEqualTo: name)
        .get();
    if (dup.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('同じ種別名は登録できません')));
      return;
    }
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('product_categories')
        .add({
          'name': name,
          'displayOrder': displayOrder,
          'createdAt': Timestamp.now(),
        });
    _nameController.clear();
    _orderController.clear();
    await fetchProductCategories();
  }

  Future<void> updateProductCategory(
    DocumentSnapshot doc,
    String newName,
    int newOrder,
  ) async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('product_categories')
        .doc(doc.id)
        .update({'name': newName, 'displayOrder': newOrder});
    await fetchProductCategories();
  }

  Future<void> deleteProductCategory(DocumentSnapshot doc) async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('product_categories')
        .doc(doc.id)
        .delete();
    await fetchProductCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品種別管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '種別名を入力'),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '表示順'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final name = _nameController.text;
                    final order = int.tryParse(_orderController.text) ?? 0;
                    await addProductCategory(name, order);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: productCategories.length,
              itemBuilder: (context, index) {
                final doc = productCategories[index];
                return ListTile(
                  title: Text(doc['name'] ?? ''),
                  subtitle: Text('表示順: ${doc['displayOrder'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final nameController = TextEditingController(
                            text: doc['name'] ?? '',
                          );
                          final orderController = TextEditingController(
                            text: (doc['displayOrder'] ?? '').toString(),
                          );
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('種別を編集'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                        labelText: '種別名',
                                      ),
                                    ),
                                    TextField(
                                      controller: orderController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: '表示順',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop({
                                      'name': nameController.text,
                                      'order':
                                          int.tryParse(orderController.text) ??
                                          0,
                                    }),
                                    child: const Text('保存'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (result != null &&
                              result['name'] != null &&
                              result['name'].isNotEmpty) {
                            await updateProductCategory(
                              doc,
                              result['name'],
                              result['order'],
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('削除の確認'),
                              content: const Text('本当にこの種別を削除しますか？'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    '削除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await deleteProductCategory(doc);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
