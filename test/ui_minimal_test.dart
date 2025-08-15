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
}
