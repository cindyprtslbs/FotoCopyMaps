class Category {
  final int id;
  final String name;
  final String? icon; // emoji atau nama icon

  const Category({
    required this.id,
    required this.name,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
      };

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
