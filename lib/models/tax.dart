class Tax {
  final String id;
  final String userId;
  final String name;
  final double rate;

  Tax({
    required this.id,
    required this.userId,
    required this.name,
    required this.rate,
  });

  factory Tax.fromMap(Map<String, dynamic> map, String id) {
    return Tax(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      rate: (map['rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name, 'rate': rate};
  }
}
