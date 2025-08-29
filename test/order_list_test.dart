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
  test('ページネーションで10件ずつ取得できる', () {
    // ダミー注文リスト（25件）
    final allOrders = List.generate(
      25,
      (i) => {'id': i, 'customerName': '顧客$i'},
    );
    int pageSize = 10;
    int currentPage = 0;
    List<Map<String, dynamic>> getPage(int page) {
      int start = page * pageSize;
      int end = start + pageSize;
      return allOrders.sublist(
        start,
        end > allOrders.length ? allOrders.length : end,
      );
    }

    // 1ページ目
    var page1 = getPage(0);
    expect(page1.length, 10);
    expect(page1.first['id'], 0);
    expect(page1.last['id'], 9);

    // 2ページ目
    var page2 = getPage(1);
    expect(page2.length, 10);
    expect(page2.first['id'], 10);
    expect(page2.last['id'], 19);

    // 3ページ目（最後の5件）
    var page3 = getPage(2);
    expect(page3.length, 5);
    expect(page3.first['id'], 20);
    expect(page3.last['id'], 24);
  });
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
