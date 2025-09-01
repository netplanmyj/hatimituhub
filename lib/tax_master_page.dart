import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaxMasterPage extends StatefulWidget {
  const TaxMasterPage({super.key});

  @override
  State<TaxMasterPage> createState() => _TaxMasterPageState();
}

class _TaxMasterPageState extends State<TaxMasterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  List<DocumentSnapshot> taxes = [];

  @override
  void initState() {
    super.initState();
    fetchTaxes();
  }

  Future<void> fetchTaxes() async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('taxes')
        .orderBy('rate')
        .get();
    setState(() {
      taxes = snapshot.docs;
    });
  }

  Future<void> addTax(String name, double rate) async {
    if (name.isEmpty) return;
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    // 重複チェック
    final dup = await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('taxes')
        .where('name', isEqualTo: name)
        .get();
    if (dup.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('同じ税率名は登録できません')));
      return;
    }
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('taxes')
        .add({'name': name, 'rate': rate, 'createdAt': Timestamp.now()});
    _nameController.clear();
    _rateController.clear();
    await fetchTaxes();
  }

  Future<void> updateTax(
    DocumentSnapshot doc,
    String newName,
    double newRate,
  ) async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('taxes')
        .doc(doc.id)
        .update({'name': newName, 'rate': newRate});
    await fetchTaxes();
  }

  Future<void> deleteTax(DocumentSnapshot doc) async {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    if (teamId == null) return;
    await FirebaseFirestore.instance
        .collection('team_data')
        .doc(teamId)
        .collection('taxes')
        .doc(doc.id)
        .delete();
    await fetchTaxes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('税率マスタ管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '税率名 (例: 8%)'),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '税率 (例: 0.08)',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final name = _nameController.text;
                    final rate = double.tryParse(_rateController.text) ?? 0.0;
                    await addTax(name, rate);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taxes.length,
              itemBuilder: (context, index) {
                final doc = taxes[index];
                return ListTile(
                  title: Text(doc['name'] ?? ''),
                  subtitle: Text('税率: ${(doc['rate'] ?? '').toString()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final nameController = TextEditingController(
                            text: doc['name'] ?? '',
                          );
                          final rateController = TextEditingController(
                            text: (doc['rate'] ?? '').toString(),
                          );
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('税率を編集'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                        labelText: '税率名',
                                      ),
                                    ),
                                    TextField(
                                      controller: rateController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: '税率',
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
                                      'rate':
                                          double.tryParse(
                                            rateController.text,
                                          ) ??
                                          0.0,
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
                            await updateTax(
                              doc,
                              result['name'],
                              result['rate'],
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
                              content: const Text('本当にこの税率を削除しますか？'),
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
                            await deleteTax(doc);
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
