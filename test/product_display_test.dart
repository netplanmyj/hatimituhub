import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('商品名・区分名・価格が表示される', (WidgetTester tester) async {
    // モックデータ
    final mockProducts = [
      {'name': 'はちみつA', 'price': 1200, 'type': 1},
      {'name': 'はちみつB', 'price': 1500, 'type': 2},
    ];
    final mockTypes = {1: '卸', 2: 'イベント'};

    // テスト用Widget
    Widget testWidget = MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: mockProducts.length,
          itemBuilder: (context, index) {
            final data = mockProducts[index];
            final typeLabel = mockTypes[data['type']] ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(data['name'] as String)),
                    Text('¥${data['price']}'),
                  ],
                ),
                Text(typeLabel, style: const TextStyle(fontSize: 12)),
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
    expect(find.text('¥1200'), findsOneWidget);
    expect(find.text('はちみつB'), findsOneWidget);
    expect(find.text('イベント'), findsOneWidget);
    expect(find.text('¥1500'), findsOneWidget);
  });
}
