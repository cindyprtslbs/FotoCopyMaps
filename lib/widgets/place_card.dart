import 'package:flutter/material.dart';
import '../models/place_model.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final String? distance; // null jika GPS mati
  final VoidCallback onTap;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4),
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: const Color(0xFF4A90D9).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // Icon avatar
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90D9), Color(0xFF1A5FA8)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(place.name, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2340), letterSpacing: -0.3,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF4A90D9)),
                      const SizedBox(width: 3),
                      Expanded(child: Text(place.address, style: const TextStyle(
                        fontSize: 13, color: Color(0xFF7A8499), height: 1.3,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 4),
                    // Distance badge OR description
                    if (distance != null)
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.near_me_rounded, size: 11, color: Color(0xFF4A90D9)),
                            const SizedBox(width: 3),
                            Text(distance!, style: const TextStyle(
                              fontSize: 11, color: Color(0xFF4A90D9), fontWeight: FontWeight.w600,
                            )),
                          ]),
                        ),
                      ])
                    else
                      Text(place.description, style: const TextStyle(
                        fontSize: 12, color: Color(0xFFADB5C8), height: 1.4,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCDD2DE), size: 24),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}