import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DummyOrderInputPage extends StatelessWidget {
  const DummyOrderInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注文入力')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('顧客'),
          Text('注文日:'),
          Text('注文明細'),
          Text('明細追加'),
          Text('注文追加'),
        ],
      ),
    );
  }
}

class DummyApp extends StatelessWidget {
  const DummyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => const DummyOrderInputPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: const Center(child: Text('商品一覧')),
      ),
    );
  }
}

class DummyOrderListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const DummyOrderListScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('注文一覧')),
        body: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['customerName'], key: Key('customerName_$index')),
                  ...List.generate(order['items'].length, (itemIdx) {
                    final item = order['items'][itemIdx];
                    return Row(
                      children: [
                        Text(
                          item['productName'],
                          key: Key('productName_${index}_$itemIdx'),
                        ),
                        Text(
                          '${item['quantity']}',
                          key: Key('quantity_${index}_$itemIdx'),
                        ),
                        Text(
                          '${item['amount']}',
                          key: Key('amount_${index}_$itemIdx'),
                        ),
                      ],
                    );
                  }),
                  Text('合計: ${order['total']}', key: Key('total_$index')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  testWidgets('商品一覧画面にカートアイコンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const DummyApp());
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
  });

  testWidgets('カートアイコンタップで注文入力画面に遷移し、主要項目が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const DummyApp());
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pumpAndSettle();
    expect(find.text('注文入力'), findsOneWidget);
    expect(find.text('顧客'), findsOneWidget);
    expect(find.text('注文日:'), findsOneWidget);
    expect(find.text('注文明細'), findsOneWidget);
    expect(find.text('明細追加'), findsOneWidget);
    expect(find.text('注文追加'), findsOneWidget);
  });

  testWidgets('注文一覧画面に注文データが表示される', (WidgetTester tester) async {
    final orders = [
      {
        'customerName': '山田太郎',
        'items': [
          {'productName': 'はちみつA', 'quantity': 2, 'amount': 1200},
          {'productName': 'はちみつB', 'quantity': 1, 'amount': 800},
        ],
        'total': 2000,
      },
      {
        'customerName': '佐藤花子',
        'items': [
          {'productName': 'はちみつC', 'quantity': 3, 'amount': 2400},
        ],
        'total': 2400,
      },
    ];

    await tester.pumpWidget(DummyOrderListScreen(orders: orders));

    // 顧客名
    expect(find.text('山田太郎'), findsOneWidget);
    expect(find.text('佐藤花子'), findsOneWidget);
    // 商品名
    expect(find.text('はちみつA'), findsOneWidget);
    expect(find.text('はちみつB'), findsOneWidget);
    expect(find.text('はちみつC'), findsOneWidget);
    // 数量
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // 金額
    expect(find.text('1200'), findsOneWidget);
    expect(find.text('800'), findsOneWidget);
    expect(find.text('2400'), findsOneWidget);
    // 合計
    expect(find.text('合計: 2000'), findsOneWidget);
    expect(find.text('合計: 2400'), findsOneWidget);
  });
}
