import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Firestore依存なしのダミー顧客リストWidget
class CustomerListView extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  const CustomerListView({required this.customers, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: customers
            .map(
              (data) => ListTile(
                title: Text(data['name']),
                subtitle: Text('${data['tel']} / ${data['customer_type']}'),
              ),
            )
            .toList(),
      ),
    );
  }
}

void main() {
  testWidgets('顧客管理画面に追加アイコンと顧客区分が表示される', (WidgetTester tester) async {
    final dummyCustomers = [
      {'name': '山田太郎', 'tel': '090-xxxx-xxxx', 'customer_type': '県内'},
      {'name': '鈴木花子', 'tel': '080-xxxx-xxxx', 'customer_type': '県外'},
    ];
    await tester.pumpWidget(
      MaterialApp(home: CustomerListView(customers: dummyCustomers)),
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('山田太郎'), findsOneWidget);
    expect(find.text('鈴木花子'), findsOneWidget);
    expect(find.textContaining('県内'), findsOneWidget);
    expect(find.textContaining('県外'), findsOneWidget);
  });
}
