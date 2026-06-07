class Review {
  final int id;
  final int placeId;
  final String? userId;
  final double rating;
  final String? comment;
  final String? userEmail; 
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.placeId,
    this.userId,
    required this.rating,
    this.comment,
    this.userEmail, 
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      placeId: json['place_id'] as int,
      userId: json['user_id'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      userEmail: json['user_email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      };
}
