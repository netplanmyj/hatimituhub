import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'order_input.dart';
import 'order_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<int, String> typeLabels = {};
  Map<int, String> categoryLabels = {};
  Map<int, String> taxLabels = {};

  Future<void> fetchTypeLabels() async {
    final typeSnap = await FirebaseFirestore.instance.collection('types').get();
    typeLabels = {
      for (var doc in typeSnap.docs)
        int.tryParse(doc.id) ?? 0: doc['typeLabel'] as String,
    };
    final catSnap = await FirebaseFirestore.instance
        .collection('categories')
        .get();
    categoryLabels = {
      for (var doc in catSnap.docs)
        int.tryParse(doc.id) ?? 0: doc['categoryLabel'] as String,
    };
    final taxSnap = await FirebaseFirestore.instance.collection('taxes').get();
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
                MaterialPageRoute(builder: (context) => const OrderListPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: '注文入力',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OrderInputPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                            padding: const EdgeInsets.only(
                              top: 4.0,
                              right: 8.0,
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        if (categoryLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                              right: 8.0,
                            ),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
