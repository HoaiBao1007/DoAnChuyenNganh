class Category {
  final int id;
  final String name;
  final String? description;
  final bool active;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.active,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      active: json['active'] ?? true,
    );
  }
}
