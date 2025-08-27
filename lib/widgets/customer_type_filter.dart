import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerTypeFilter extends StatelessWidget {
  final List<DocumentSnapshot> customerTypes;
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
            ...customerTypes.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final label = data['typeLabel'] ?? doc.id;
              return DropdownMenuItem(value: doc.id, child: Text(label));
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
