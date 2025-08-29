import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  bool _isProcessing = false;
  String _message = '';

  Future<void> _insertInitialData() async {
    setState(() {
      _isProcessing = true;
      _message = '';
    });
    final firestore = FirebaseFirestore.instance;
    // teamId = userId方式で初期データ投入
    final currentUser = FirebaseAuth.instance.currentUser;
    final teamId = currentUser?.uid;
    if (teamId == null) {
      setState(() {
        _isProcessing = false;
        _message = 'ユーザー情報が取得できません。ログインしてください。';
      });
      return;
    }
    // 各コレクションの初期データ
    final initialData = <String, List<Map<String, dynamic>>>{
      'customer_types': [
        {'name': '法人', 'createdAt': Timestamp.now()},
        {'name': '個人', 'createdAt': Timestamp.now()},
      ],
      'customers': [
        {'name': 'テスト顧客A', 'createdAt': Timestamp.now()},
        {'name': 'テスト顧客B', 'createdAt': Timestamp.now()},
      ],
      'orders': [
        {'orderNo': '0001', 'createdAt': Timestamp.now()},
        {'orderNo': '0002', 'createdAt': Timestamp.now()},
      ],
      'product_categories': [
        {'name': '食品', 'createdAt': Timestamp.now()},
        {'name': '雑貨', 'createdAt': Timestamp.now()},
      ],
      'product_types': [
        {'name': '通常', 'createdAt': Timestamp.now()},
        {'name': '特価', 'createdAt': Timestamp.now()},
      ],
      'products': [
        {'name': 'はちみつ', 'price': 1000, 'createdAt': Timestamp.now()},
        {'name': 'キャンディ', 'price': 300, 'createdAt': Timestamp.now()},
      ],
      'taxes': [
        {'name': '標準税率', 'rate': 10.0, 'createdAt': Timestamp.now()},
        {'name': '軽減税率', 'rate': 8.0, 'createdAt': Timestamp.now()},
      ],
    };

    int totalInserted = 0;
    final insertedDetails = <String, int>{};
    for (final entry in initialData.entries) {
      final colName = entry.key;
      final dataList = entry.value;
      final colRef = firestore
          .collection('team_data')
          .doc(teamId)
          .collection(colName);
      final snapshot = await colRef.get();
      // 既存データのname/orderNoで重複判定
      final existingKeys = snapshot.docs.map((doc) {
        if (doc.data().containsKey('name')) return doc['name'] as String;
        if (doc.data().containsKey('orderNo')) return doc['orderNo'] as String;
        return '';
      }).toSet();
      int insertedCount = 0;
      for (var data in dataList) {
        String key =
            data['name']?.toString() ?? data['orderNo']?.toString() ?? '';
        if (key.isNotEmpty && !existingKeys.contains(key)) {
          await colRef.add(data);
          insertedCount++;
        }
      }
      totalInserted += insertedCount;
      insertedDetails[colName] = insertedCount;
    }
    setState(() {
      _isProcessing = false;
      if (totalInserted == 0) {
        _message = 'すでに初期データが投入されています。';
      } else {
        final details = insertedDetails.entries
            .map((e) => '${e.key}: ${e.value}件')
            .join(', ');
        _message = '初期データ投入が完了しました（合計$totalInserted件追加）\n$details';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('初期セットアップ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isProcessing ? null : _insertInitialData,
              child: const Text('初期データ投入'),
            ),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
