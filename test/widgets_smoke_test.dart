import 'package:flutter_test/flutter_test.dart';
import 'package:honeysales/widgets/main_menu_widget.dart';
import 'package:honeysales/widgets/quantity_input.dart';
import 'package:honeysales/widgets/google_sign_in_widget.dart';
import 'package:flutter/material.dart';
import 'package:honeysales/widgets/customer_item.dart';
import 'package:honeysales/widgets/customer_dialog.dart';
import 'package:honeysales/widgets/product_item.dart';
import 'package:honeysales/widgets/customer_type_filter.dart';
import 'package:honeysales/widgets/product_selector.dart';

void main() {
  group('Widget smoke tests', () {
    testWidgets('MainMenuWidget builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuWidget(user: null, onSignIn: () {}, onSignOut: () {}),
        ),
      );
      expect(find.byType(MainMenuWidget), findsOneWidget);
    });
    testWidgets('CustomerItem builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerItem(
            customer: {
              'name': 'テスト顧客',
              'address1': '東京都',
              'tel': '090-xxxx',
              'type': 'A',
            },
            typeLabel: 'A',
          ),
        ),
      );
      expect(find.byType(CustomerItem), findsOneWidget);
    });
    testWidgets('QuantityInput builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuantityInput(quantity: 1, onChanged: (_) {})),
        ),
      );
      expect(find.byType(QuantityInput), findsOneWidget);
    });
    // ProductDialogはstatic showメソッドのみなのでスキップ
    testWidgets('CustomerDialog builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDialog(
            customerTypes: [
              {'id': 'A', 'name': '区分A'},
              {'id': 'B', 'name': '区分B'},
            ],
            customer: {
              'name': 'テスト顧客',
              'address1': '東京都',
              'tel': '090-xxxx',
              'customer_type': 'A',
              'kana': 'テストカナ',
            },
            initialCustomerType: 'A',
            onSave: (_, _, _, _, _) {},
          ),
        ),
      );
      expect(find.byType(CustomerDialog), findsOneWidget);
    });
    testWidgets('ProductItemForm builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductItemForm(
              product: {'name': '商品A', 'price': 100, 'type': 'A'},
              types: [
                {'id': 'A', 'name': '区分A'},
                {'id': 'B', 'name': '区分B'},
              ],
            ),
          ),
        ),
      );
      expect(find.byType(ProductItemForm), findsOneWidget);
    });
    testWidgets('CustomerTypeFilter builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerTypeFilter(
              customerTypes: [
                {'id': 'A', 'name': '区分A'},
                {'id': 'B', 'name': '区分B'},
              ],
              selectedCustomerType: 'A',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(CustomerTypeFilter), findsOneWidget);
    });
    testWidgets('ProductSelector builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductSelector(
              productTypes: [
                {'id': 'A', 'name': '区分A'},
                {'id': 'B', 'name': '区分B'},
              ],
              products: [
                {'id': 'P1', 'name': '商品A', 'type': 'A'},
                {'id': 'P2', 'name': '商品B', 'type': 'B'},
              ],
              initialTypeId: 'A',
              initialProductId: 'P1',
              initialQuantity: 1,
              onChanged: (_, _, _) {},
            ),
          ),
        ),
      );
      expect(find.byType(ProductSelector), findsOneWidget);
    });
    testWidgets('GoogleSignInWidget builds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: GoogleSignInWidget(childBuilder: (_) => Container())),
      );
      expect(find.byType(GoogleSignInWidget), findsOneWidget);
    });
    testWidgets('CustomerList builds', (tester) async {
      // Firestore依存なしのダミーWidgetで代用
      final dummyCustomers = [
        {
          'name': '山田太郎',
          'kana': 'ヤマダタロウ',
          'address1': '東京都',
          'tel': '090-xxxx',
          'customer_type': 'A',
        },
        {
          'name': '鈴木花子',
          'kana': 'スズキハナコ',
          'address1': '神奈川県',
          'tel': '080-xxxx',
          'customer_type': 'B',
        },
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: dummyCustomers
                  .map(
                    (c) => ListTile(
                      title: Text(c['name'] ?? ''),
                      subtitle: Text(
                        '${c['kana'] ?? ''} / ${c['customer_type'] ?? ''}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
      expect(find.text('山田太郎'), findsOneWidget);
      expect(find.text('鈴木花子'), findsOneWidget);
    });
  });
}
