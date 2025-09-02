import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerList extends StatelessWidget {
  final List<DocumentSnapshot> customerTypes;
  final String selectedCustomerType;
  final void Function(DocumentSnapshot customer)? onEdit;

  const CustomerList({
    super.key,
    required this.customerTypes,
    required this.selectedCustomerType,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final teamId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('team_data')
          .doc(teamId)
          .collection('customers')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var customers = snapshot.data?.docs ?? [];
        if (selectedCustomerType.isNotEmpty) {
          customers = customers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['customer_type'] == selectedCustomerType;
          }).toList();
        }
        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final data = customer.data() as Map<String, dynamic>;
            String typeLabel = '';
            if (customerTypes.isNotEmpty && data['customer_type'] != null) {
              try {
                final typeDoc = customerTypes.firstWhere(
                  (doc) => doc.id == data['customer_type'],
                );
                final typeData = typeDoc.data() as Map<String, dynamic>;
                typeLabel = typeData['name'] ?? '';
              } catch (e) {
                typeLabel = '';
              }
            }
            return CustomerItem(
              customer: customer,
              onEdit: () => onEdit?.call(customer),
              typeLabel: typeLabel,
            );
          },
        );
      },
    );
  }
}
