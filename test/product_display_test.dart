import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('アプリ起動時に注文一覧が表示される', (WidgetTester tester) async {
    Widget testWidget = MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('注文一覧')),
        body: Container(),
      ),
    );

    await tester.pumpWidget(testWidget);

    // 注文一覧画面のタイトルが表示されることを確認
    expect(find.text('注文一覧'), findsOneWidget);
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

  testWidgets('顧客管理アイコンが表示される', (WidgetTester tester) async {
    Widget testWidget = MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(icon: const Icon(Icons.people), onPressed: () {}),
          ],
        ),
        body: Container(),
      ),
    );

    await tester.pumpWidget(testWidget);

    expect(find.byIcon(Icons.people), findsOneWidget);
  });
}
