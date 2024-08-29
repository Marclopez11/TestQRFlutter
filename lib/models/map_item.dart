import 'package:latlong2/latlong.dart';

class MapItem {
  final String id;
  final String title;
  final String description;
  final LatLng position;
  final String imageUrl;
  final int categoryId;
  final String categoryName;

  MapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
  });
}
