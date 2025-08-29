class ProductType {
  final String id;
  final String userId;
  final String name;

  ProductType({required this.id, required this.userId, required this.name});

  factory ProductType.fromMap(Map<String, dynamic> map, String id) {
    return ProductType(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name};
  }
}
