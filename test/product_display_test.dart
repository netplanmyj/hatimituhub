import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:honeysales/main.dart';

// テスト用Userのモック
class MockUser implements User {
  @override
  String? get displayName => 'テストユーザー';
  @override
  String? get email => 'test@example.com';
  @override
  String? get photoURL => null;
  // 必要なgetterのみ実装。他はthrow UnimplementedErrorでOK。
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('未ログイン状態では各ボタンが表示されない', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HoneysalesHome(testUser: null)),
    );
    expect(find.byIcon(Icons.inventory), findsNothing);
    expect(find.byIcon(Icons.list_alt), findsNothing);
    expect(find.byIcon(Icons.add_shopping_cart), findsNothing);
    expect(find.byIcon(Icons.people), findsNothing);
    expect(find.text('Googleでログイン'), findsOneWidget);
  });

  testWidgets('ログイン状態では各ボタンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HoneysalesHome(testUser: MockUser())),
    );
    expect(find.byIcon(Icons.inventory), findsOneWidget);
    expect(find.byIcon(Icons.list_alt), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
  });
}
