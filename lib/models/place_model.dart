class Place {

  final int id;
  final int categoryId;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String description;

  Place({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.description,
  });

  factory Place.fromJson(Map<String, dynamic> json) {

    return Place(
      id: int.parse(json['id'].toString()),
      categoryId:
          int.parse(json['category_id'].toString()),
      name: json['name'],
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
      address: json['address'],
      description: json['description'],
    );
  }
}