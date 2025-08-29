class ProductCategory {
  final String id;
  final String userId;
  final String name;

  ProductCategory({required this.id, required this.userId, required this.name});

  factory ProductCategory.fromMap(Map<String, dynamic> map, String id) {
    return ProductCategory(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name};
  }
}
