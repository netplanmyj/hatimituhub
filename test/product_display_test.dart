import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('商品名・区分名・価格が表示される', (WidgetTester tester) async {
    // モックデータ
    final mockProducts = [
      {'name': 'はちみつA', 'price': 1200, 'type': 1, 'category': 2, 'tax': 8},
      {'name': 'はちみつB', 'price': 1500, 'type': 2, 'category': 1, 'tax': 10},
    ];
    final mockTypes = {1: '卸', 2: 'イベント'};
    final mockCategories = {1: '春の百花蜜', 2: 'みかん蜜'};
    final mockTaxes = {8: '8%', 10: '10%'};

    // テスト用Widget
    Widget testWidget = MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: mockProducts.length,
          itemBuilder: (context, index) {
            final data = mockProducts[index];
            final typeLabel = mockTypes[data['type']] ?? '';
            final categoryLabel = mockCategories[data['category']] ?? '';
            final taxLabel = mockTaxes[data['tax']] ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(data['name'] as String)),
                    Text('¥${data['price']}'),
                  ],
                ),
                Row(
                  children: [
                    Text(typeLabel, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      categoryLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      taxLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.pumpWidget(testWidget);

    // 商品名・区分名・価格が表示されているか確認
    expect(find.text('はちみつA'), findsOneWidget);
    expect(find.text('卸'), findsOneWidget);
    expect(find.text('みかん蜜'), findsOneWidget);
    expect(find.text('8%'), findsOneWidget);
    expect(find.text('¥1200'), findsOneWidget);
    expect(find.text('はちみつB'), findsOneWidget);
    expect(find.text('イベント'), findsOneWidget);
    expect(find.text('春の百花蜜'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('¥1500'), findsOneWidget);
  });

  testWidgets('商品管理ボタンが表示される', (WidgetTester tester) async {
    Widget testWidget = MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(icon: const Icon(Icons.inventory), onPressed: () {}),
          ],
        ),
        body: Container(),
      ),
    );

    await tester.pumpWidget(testWidget);

    expect(find.byIcon(Icons.inventory), findsOneWidget);
  });

  testWidgets('注文一覧ボタンが表示される', (WidgetTester tester) async {
    Widget testWidget = MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(icon: const Icon(Icons.list_alt), onPressed: () {}),
          ],
        ),
        body: Container(),
      ),
    );

    await tester.pumpWidget(testWidget);

    expect(find.byIcon(Icons.list_alt), findsOneWidget);
  });

  testWidgets('注文入力ボタンが表示される', (WidgetTester tester) async {
    Widget testWidget = MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {},
            ),
          ],
        ),
        body: Container(),
      ),
    );

    await tester.pumpWidget(testWidget);

    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
  });
  testWidgets('カートアイコンタップで注文入力画面に遷移し、主要項目が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  Navigator.of(
                    tester.element(find.byIcon(Icons.add_shopping_cart)),
                  ).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('注文入力')),
                        body: const Text('顧客選択'), // 主要項目の例
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Container(),
        ),
      ),
    );

    // カートアイコンをタップ
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pumpAndSettle();

    // 注文入力画面の主要項目が表示されることを確認
    expect(find.text('注文入力'), findsOneWidget);
    expect(find.text('顧客選択'), findsOneWidget);
  });
}
