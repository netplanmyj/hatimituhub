class CustomerType {
  final String id;
  final String userId;
  final String name;

  CustomerType({required this.id, required this.userId, required this.name});

  factory CustomerType.fromMap(Map<String, dynamic> map, String id) {
    return CustomerType(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name};
  }
}
