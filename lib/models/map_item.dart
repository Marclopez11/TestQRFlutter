import 'package:latlong2/latlong.dart';

class MapItem {
  final String id;
  final String title;
  final String description;
  final LatLng position;

  MapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
  });
}
