import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String userId;
  final String name;
  final String typeId;
  final Timestamp createdAt;

  Customer({
    required this.id,
    required this.userId,
    required this.name,
    required this.typeId,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      typeId: map['typeId'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'typeId': typeId,
      'createdAt': createdAt,
    };
  }
}
