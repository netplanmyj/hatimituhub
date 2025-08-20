import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'order_input.dart';
import 'order_list_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;
  runApp(MyApp(firestore: firestore));
}

class MyApp extends StatelessWidget {
  final FirebaseFirestore firestore;
  const MyApp({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', firestore: firestore),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final FirebaseFirestore firestore;
  const MyHomePage({super.key, required this.title, required this.firestore});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<int, String> typeLabels = {};
  Map<int, String> categoryLabels = {};
  Map<int, String> taxLabels = {};

  Future<void> fetchTypeLabels() async {
    final typeSnap = await widget.firestore.collection('types').get();
    typeLabels = {
      for (var doc in typeSnap.docs)
        int.tryParse(doc.id) ?? 0: doc['typeLabel'] as String,
    };
    final catSnap = await widget.firestore.collection('categories').get();
    categoryLabels = {
      for (var doc in catSnap.docs)
        int.tryParse(doc.id) ?? 0: doc['categoryLabel'] as String,
    };
    final taxSnap = await widget.firestore.collection('taxes').get();
    taxLabels = {
      for (var doc in taxSnap.docs)
        int.tryParse(doc.id) ?? 0: doc['taxLabel'] as String,
    };
  }

  @override
  void initState() {
    super.initState();
    fetchTypeLabels().then((_) => setState(() {}));
  }

  Widget buildProductTile(Map<String, dynamic> data) {
    final typeCode = data['type'] is int
        ? data['type']
        : int.tryParse(data['type'].toString()) ?? 0;
    final typeLabel = typeLabels[typeCode] ?? '';
    final categoryCode = data['category'] is int
        ? data['category']
        : int.tryParse(data['category']?.toString() ?? '') ?? 0;
    final categoryLabel = categoryLabels[categoryCode] ?? '';
    final taxCode = data['tax'] is int
        ? data['tax']
        : int.tryParse(data['tax']?.toString() ?? '') ?? 0;
    final taxLabel = taxLabels[taxCode] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['name'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Text(
                data['price'] != null ? '¥${data['price']}' : '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (typeLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              if (categoryLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                  child: Text(
                    categoryLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              if (taxLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    taxLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: '注文一覧',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => OrderListPage(firestore: widget.firestore)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: '注文入力',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => OrderInputPage(firestore: widget.firestore)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('商品データがありません'));
          }
          final products = snapshot.data!.docs;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              return buildProductTile(data);
            },
          );
        },
      ),
    );
  }
}
