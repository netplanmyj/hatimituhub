import 'package:flutter/material.dart';

class CustomerTypeFilter extends StatelessWidget {
  final List<dynamic> customerTypes;
  final String selectedCustomerType;
  final ValueChanged<String> onChanged;

  const CustomerTypeFilter({
    super.key,
    required this.customerTypes,
    required this.selectedCustomerType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('顧客区分: '),
        DropdownButton<String>(
          value: selectedCustomerType.isEmpty ? null : selectedCustomerType,
          hint: const Text('すべて'),
          items: [
            const DropdownMenuItem(value: '', child: Text('すべて')),
            ...customerTypes.map((typeDoc) {
              final typeName = typeDoc['name'] ?? typeDoc.id;
              final id =
                  (typeDoc is Map ? typeDoc['id'] : typeDoc.id)?.toString() ??
                  '';
              return DropdownMenuItem<String>(value: id, child: Text(typeName));
            }),
          ],
          onChanged: (value) {
            onChanged(value ?? '');
          },
        ),
      ],
    );
  }
}
