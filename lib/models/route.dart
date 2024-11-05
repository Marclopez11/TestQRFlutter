import 'package:latlong2/latlong.dart';

class RouteModel {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String circuitType;
  final String routeType;
  final double distance;
  final int hours;
  final int minutes;
  final double maxAltitude;
  final double minAltitude;
  final double positiveElevation;
  final double negativeElevation;
  final LatLng location;
  final String? mainImage;
  final List<String> imageGallery;
  final String? kmlUrl;

  RouteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.circuitType,
    required this.routeType,
    required this.distance,
    required this.hours,
    required this.minutes,
    required this.maxAltitude,
    required this.minAltitude,
    required this.positiveElevation,
    required this.negativeElevation,
    required this.location,
    this.mainImage,
    required this.imageGallery,
    this.kmlUrl,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['uuid'][0]['value'],
      title: json['title'][0]['value'],
      description: json['field_route_description'][0]['value'],
      difficulty: json['field_route_difficulty'][0]['value'],
      circuitType: json['field_route_circuit_type'][0]['value'],
      routeType: json['field_route_type'][0]['value'],
      distance: double.parse(json['field_route_distance'][0]['value']),
      hours: json['field_route_hour'][0]['value'],
      minutes: json['field_route_minutes'][0]['value'],
      maxAltitude:
          double.parse(json['field_route_maximum_altitude'][0]['value']),
      minAltitude:
          double.parse(json['field_route_minimum_altitude'][0]['value']),
      positiveElevation:
          double.parse(json['field_route_positive_elevation'][0]['value']),
      negativeElevation:
          double.parse(json['field_route_negative_elevation'][0]['value']),
      location: _parseLocation(json['field_route_location'][0]['value']),
      mainImage: json['field_route_main_image']?[0]?['url'],
      imageGallery: json['field_route_image_gallery'] != null
          ? List<String>.from(json['field_route_image_gallery']
              .map((image) => image['url'] ?? ''))
          : [],
      kmlUrl: json['field_route_kml']?[0]?['url'],
    );
  }

  static LatLng _parseLocation(String value) {
    final parts = value.split(',');
    final lat = double.parse(parts[0].trim());
    final lng = double.parse(parts[1].trim());
    return LatLng(lat, lng);
  }
}
