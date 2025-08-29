import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String userId;
  final String name;
  final String categoryId;
  final String typeId;
  final double price;
  final Timestamp createdAt;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.categoryId,
    required this.typeId,
    required this.price,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      typeId: map['typeId'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'categoryId': categoryId,
      'typeId': typeId,
      'price': price,
      'createdAt': createdAt,
    };
  }
}
