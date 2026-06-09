class Place {
  final int id;
  final int? categoryId;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final String? description;
  final String? photoUrl;
  final double? rating;
  final String? openHours;   // contoh: "08:00 - 21:00"
  final String? categoryName; // join dari tabel categories

  // Dihitung saat runtime, bukan dari DB
  double? distanceMeters;

  Place({
    required this.id,
    this.categoryId,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.description,
    this.photoUrl,
    this.rating,
    this.openHours,
    this.categoryName,
    this.distanceMeters,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      openHours: json['opening_hours'] as String?,
      // Ambil dari join: categories!inner(name)
      categoryName: json['categories'] != null
          ? (json['categories'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'lat': lat,
        'lng': lng,
        'address': address,
        'description': description,
        'photo_url': photoUrl,
        'rating': rating,
        'open_hours': openHours,
      };

  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  @override
  String toString() => 'Place(id: $id, name: $name, lat: $lat, lng: $lng)';

  static fromMap(e) {}
}
