import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatimituhub/main.dart';
import 'package:hatimituhub/flavor_config.dart';
import 'helpers/mock_auth_service.dart';

void main() {
  setUpAll(() {
    FlavorConfig.initialize(flavor: Flavor.dev);
  });

  testWidgets('未ログイン状態では各ボタンが表示されない', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HatimituhubHome(testUser: null, authService: MockAuthService()),
      ),
    );
    expect(find.byIcon(Icons.inventory), findsNothing);
    expect(find.byIcon(Icons.list_alt), findsNothing);
    expect(find.byIcon(Icons.add_shopping_cart), findsNothing);
    expect(find.byIcon(Icons.people), findsNothing);
    expect(find.text('Googleでログイン'), findsOneWidget);
  });

  testWidgets('ログイン状態では各ボタンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HatimituhubHome(
          testUser: MockUser(),
          authService: MockAuthService(),
        ),
      ),
    );
    expect(find.byIcon(Icons.inventory), findsOneWidget);
    expect(find.byIcon(Icons.list_alt), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
  });
}
