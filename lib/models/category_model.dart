class Category {

  final int id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Category.fromJson(
    Map<String, dynamic> json,
  ) {

    return Category(

      id:
          int.parse(
        json['id'].toString(),
      ),

      name:
          json['name'] ?? '',

      icon:
          json['icon'] ?? '',
    );
  }
}