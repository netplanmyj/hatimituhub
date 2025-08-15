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
}
