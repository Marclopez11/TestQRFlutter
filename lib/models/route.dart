import 'package:latlong2/latlong.dart';

class RouteModel {
  final int id;
  final String title;
  final String description;
  final String? mainImage;
  final LatLng location;
  final double distance;
  final int hours;
  final int minutes;
  final double positiveElevation;
  final double negativeElevation;
  final int difficultyId;
  final int circuitTypeId;
  final int routeTypeId;
  final String? gpxFile;
  final String? kmlUrl;

  RouteModel({
    required this.id,
    required this.title,
    required this.description,
    this.mainImage,
    required this.location,
    required this.distance,
    required this.hours,
    required this.minutes,
    required this.positiveElevation,
    required this.negativeElevation,
    required this.difficultyId,
    required this.circuitTypeId,
    required this.routeTypeId,
    this.gpxFile,
    this.kmlUrl,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    try {
      // Extraer valores con manejo de nulos
      final nid = json['nid']?[0]?['value'] ?? 0;
      final title = json['title']?[0]?['value'] ?? '';
      final description = json['field_route_description']?[0]?['value'] ?? '';
      final mainImage = json['field_route_main_image']?.isNotEmpty == true
          ? json['field_route_main_image'][0]['url']
          : null;

      // Ubicación con valores por defecto de Felanitx si falta
      final lat = json['field_route_location']?[0]?['lat'] ?? 39.4699;
      final lng = json['field_route_location']?[0]?['lng'] ?? 3.1150;

      // Valores numéricos con manejo de nulos
      final distance = double.tryParse(
              json['field_route_distance']?[0]?['value']?.toString() ?? '0') ??
          0.0;
      final hours = int.tryParse(
              json['field_route_hours']?[0]?['value']?.toString() ?? '0') ??
          0;
      final minutes = int.tryParse(
              json['field_route_minutes']?[0]?['value']?.toString() ?? '0') ??
          0;
      final positiveElevation = double.tryParse(
              json['field_route_positive_elevation']?[0]?['value']
                      ?.toString() ??
                  '0') ??
          0.0;
      final negativeElevation = double.tryParse(
              json['field_route_negative_elevation']?[0]?['value']
                      ?.toString() ??
                  '0') ??
          0.0;

      // IDs de taxonomía con valores por defecto
      final difficultyId =
          json['field_route_difficulty']?[0]?['target_id'] ?? 0;
      final circuitTypeId =
          json['field_route_circuit_type']?[0]?['target_id'] ?? 0;
      final routeTypeId = json['field_route_type']?[0]?['target_id'] ?? 0;

      // URLs opcionales
      final gpxFile = json['field_route_gpx']?.isNotEmpty == true
          ? json['field_route_gpx'][0]['url']
          : null;
      final kmlUrl = json['field_route_kml']?.isNotEmpty == true
          ? json['field_route_kml'][0]['url']
          : null;

      print('Procesando ruta exitosamente:');
      print('ID: $nid');
      print('Título: $title');
      print('Distancia: $distance');
      print('Horas: $hours');
      print('Minutos: $minutes');

      return RouteModel(
        id: nid,
        title: title,
        description: description,
        mainImage: mainImage,
        location: LatLng(lat, lng),
        distance: distance,
        hours: hours,
        minutes: minutes,
        positiveElevation: positiveElevation,
        negativeElevation: negativeElevation,
        difficultyId: difficultyId,
        circuitTypeId: circuitTypeId,
        routeTypeId: routeTypeId,
        gpxFile: gpxFile,
        kmlUrl: kmlUrl,
      );
    } catch (e, stackTrace) {
      print('Error parsing route: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}
