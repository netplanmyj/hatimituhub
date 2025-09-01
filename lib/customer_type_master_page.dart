import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerTypeMasterPage extends StatefulWidget {
  const CustomerTypeMasterPage({super.key});

  @override
  State<CustomerTypeMasterPage> createState() => _CustomerTypeMasterPageState();
}

class _CustomerTypeMasterPageState extends State<CustomerTypeMasterPage> {
  final TextEditingController _controller = TextEditingController();
  List<DocumentSnapshot> customerTypes = [];

  @override
  void initState() {
    super.initState();
    fetchCustomerTypes();
  }

  Future<void> fetchCustomerTypes() async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('customer_types')
        .orderBy('createdAt')
        .get();
    setState(() {
      customerTypes = snapshot.docs;
    });
  }

  Future<void> addCustomerType(String name) async {
    if (name.isEmpty) return;
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    // 重複チェック
    final dup = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('customer_types')
        .where('name', isEqualTo: name)
        .get();
    if (dup.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('同じ区分名は登録できません')));
      return;
    }
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('customer_types')
        .add({'name': name, 'createdAt': Timestamp.now()});
    _controller.clear();
    await fetchCustomerTypes();
  }

  Future<void> updateCustomerType(DocumentSnapshot doc, String newName) async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('customer_types')
        .doc(doc.id)
        .update({'name': newName});
    await fetchCustomerTypes();
  }

  Future<void> deleteCustomerType(DocumentSnapshot doc) async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('customer_types')
        .doc(doc.id)
        .delete();
    await fetchCustomerTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('顧客区分管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: '区分名を入力'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await addCustomerType(_controller.text);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: customerTypes.length,
              itemBuilder: (context, index) {
                final doc = customerTypes[index];
                return ListTile(
                  title: Text(doc['name'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final editController = TextEditingController(
                            text: doc['name'] ?? '',
                          );
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('区分名を編集'),
                                content: TextField(
                                  controller: editController,
                                  decoration: const InputDecoration(
                                    labelText: '新しい区分名',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pop(editController.text),
                                    child: const Text('保存'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (newName != null &&
                              newName.isNotEmpty &&
                              newName != doc['name']) {
                            await updateCustomerType(doc, newName);
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
                              content: const Text('本当にこの区分を削除しますか？'),
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
                            await deleteCustomerType(doc);
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
