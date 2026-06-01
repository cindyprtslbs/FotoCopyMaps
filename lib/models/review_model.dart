class Review {
  final int id;
  final int placeId;
  final int userId;
  final double rating;
  final String comment;

  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id:      int.parse(json['id'].toString()),
      placeId: int.parse(json['place_id'].toString()),
      userId:  int.parse((json['user_id'] ?? '0').toString()),
      rating:  double.parse(json['rating'].toString()),
      comment: json['comment'] ?? '',
    );
  }
}