import 'package:latlong2/latlong.dart';

class MapItem {
  final String id;
  final String title;
  final String description;
  final LatLng position;
  final String imageUrl;
  final int categoryId;
  final String categoryName;
  final double averageRating; // Add this line
  final bool featured;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? websiteUrl;
  final String? whatsappNumber;
  final String? phoneNumber;
  final String? email;

  MapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.averageRating, // Add this line
    this.featured = false,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.websiteUrl,
    this.whatsappNumber,
    this.phoneNumber,
    this.email,
  });
}
