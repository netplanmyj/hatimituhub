import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String customerId;
  final DateTime date;
  final List<String> productIds;

  Order({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.date,
    required this.productIds,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      customerId: map['customerId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productIds: List<String>.from(map['productIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerId': customerId,
      'date': Timestamp.fromDate(date),
      'productIds': productIds,
    };
  }
}
