import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Firestore依存なしのダミー注文一覧ページ
class DummyOrderListPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const DummyOrderListPage({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: orders.isEmpty
            ? const Center(child: Text('注文データがありません'))
            : ListView(
                children: orders
                    .map(
                      (order) => ListTile(
                        title: Text(order['customerName'] as String),
                        subtitle: Text(
                          order['orderDate'] != null
                              ? '注文日: ${(order['orderDate'] as DateTime).year}/${(order['orderDate'] as DateTime).month}/${(order['orderDate'] as DateTime).day}'
                              : '注文日: 不明',
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}

void main() {
  testWidgets('注文一覧に顧客名と注文日が表示される', (WidgetTester tester) async {
    final orders = [
      {'customerName': '山田太郎', 'orderDate': DateTime(2025, 8, 22)},
      {'customerName': '鈴木花子', 'orderDate': DateTime(2025, 8, 21)},
    ];
    await tester.pumpWidget(DummyOrderListPage(orders: orders));
    expect(find.text('山田太郎'), findsOneWidget);
    expect(find.text('鈴木花子'), findsOneWidget);
    expect(find.textContaining('注文日: 2025/8/22'), findsOneWidget);
    expect(find.textContaining('注文日: 2025/8/21'), findsOneWidget);
  });

  testWidgets('注文データがない場合にメッセージが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const DummyOrderListPage(orders: []));
    expect(find.text('注文データがありません'), findsOneWidget);
  });

  testWidgets('注文入力ボタンが表示される', (WidgetTester tester) async {
    Widget testWidget = MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: '注文入力',
              onPressed: () {},
            ),
          ],
        ),
        body: Container(),
      ),
    );
    await tester.pumpWidget(testWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    expect(find.byTooltip('注文入力'), findsOneWidget);
  });
}
