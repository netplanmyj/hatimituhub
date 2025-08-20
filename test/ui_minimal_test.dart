

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeysales/main.dart';
import 'package:honeysales/order_list_page.dart';
import 'package:honeysales/order_input.dart';
import 'package:honeysales/order_detail_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

Future<void> waitForWidget(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 3)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw FlutterError('Widget not found: $finder');
}

void main() {

  late FakeFirebaseFirestore fakeFirestore;
  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    // 顧客データ追加
    await fakeFirestore.collection('customers').add({
      'name': 'テスト顧客',
      'createdAt': DateTime.now(),
    });
    // 商品データ追加
    await fakeFirestore.collection('products').add({
      'name': 'テスト商品',
      'price': 1000,
      'createdAt': DateTime.now(),
    });
  });
  testWidgets('MyAppのトップ画面に注文一覧・注文入力アイコンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(firestore: fakeFirestore));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.list_alt), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
  });

  testWidgets('注文一覧アイコンタップでOrderListPageに遷移し、注文一覧タイトルが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(firestore: fakeFirestore));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pump();
    await waitForWidget(tester, find.text('注文一覧'));
    expect(find.text('注文一覧'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pumpAndSettle();
    expect(find.text('注文入力'), findsOneWidget);
    await tester.pumpWidget(MyApp(firestore: fakeFirestore));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pump();
    await waitForWidget(tester, find.text('注文入力'));
    expect(find.text('注文入力'), findsOneWidget);
    expect(find.text('顧客'), findsOneWidget);
    expect(find.text('注文日: '), findsOneWidget);
  testWidgets('OrderInputPageで顧客・商品選択UIが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: OrderInputPage(firestore: fakeFirestore)));
      await tester.pumpAndSettle();
      expect(find.text('顧客'), findsOneWidget);
      expect(find.text('注文日: '), findsOneWidget);
      expect(find.text('注文明細'), findsOneWidget);
      expect(find.text('明細追加'), findsOneWidget);
      expect(find.text('注文追加'), findsOneWidget);
  });
  });

  // OrderDetailPageのテスト例（orderIdはダミー）
  testWidgets('OrderInputPageのUI要素が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: OrderInputPage(firestore: fakeFirestore)));
    await waitForWidget(tester, find.text('顧客'));
    expect(find.text('顧客'), findsOneWidget);
    expect(find.text('注文日: '), findsOneWidget);
    expect(find.text('注文明細'), findsOneWidget);
    expect(find.text('明細追加'), findsOneWidget);
    expect(find.text('注文追加'), findsOneWidget);
  });
