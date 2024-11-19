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
      //print('Procesando JSON: ${json.toString()}');

      // Extraer valores con manejo de nulos y conversión segura
      final nid =
          int.tryParse(json['nid']?[0]?['value']?.toString() ?? '0') ?? 0;
      final title = json['title']?[0]?['value']?.toString() ?? '';
      final description =
          json['field_route_description']?[0]?['value']?.toString() ?? '';

      // Manejo seguro de la imagen principal
      final mainImage = json['field_route_main_image'] != null &&
              (json['field_route_main_image'] as List).isNotEmpty
          ? json['field_route_main_image'][0]['url']?.toString()
          : null;

      // Ubicación con manejo seguro de valores numéricos
      final lat = double.tryParse(
              json['field_route_location']?[0]?['lat']?.toString() ??
                  '39.4699') ??
          39.4699;
      final lng = double.tryParse(
              json['field_route_location']?[0]?['lng']?.toString() ??
                  '3.1150') ??
          3.1150;

      // Valores numéricos con conversión segura
      final distance = double.tryParse(
              json['field_route_distance']?[0]?['value']?.toString() ?? '0') ??
          0.0;

      // Manejo especial para horas y minutos que pueden venir como arrays vacíos
      final hours = json['field_route_hour'] != null &&
              (json['field_route_hour'] as List).isNotEmpty
          ? int.tryParse(
                  json['field_route_hour'][0]['value']?.toString() ?? '0') ??
              0
          : 0;

      final minutes = json['field_route_minutes'] != null &&
              (json['field_route_minutes'] as List).isNotEmpty
          ? int.tryParse(
                  json['field_route_minutes'][0]['value']?.toString() ?? '0') ??
              0
          : 0;

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

      // IDs de taxonomía con conversión segura
      final difficultyId = int.tryParse(
              json['field_route_difficulty']?[0]?['target_id']?.toString() ??
                  '0') ??
          0;
      final circuitTypeId = int.tryParse(
              json['field_route_circuit_type']?[0]?['target_id']?.toString() ??
                  '0') ??
          0;
      final routeTypeId = int.tryParse(
              json['field_route_type']?[0]?['target_id']?.toString() ?? '0') ??
          0;

      // URLs opcionales con manejo seguro
      final gpxFile = json['field_route_gpx'] != null &&
              (json['field_route_gpx'] as List).isNotEmpty
          ? json['field_route_gpx'][0]['url']?.toString()
          : null;
      final kmlUrl = json['field_route_kml'] != null &&
              (json['field_route_kml'] as List).isNotEmpty
          ? json['field_route_kml'][0]['url']?.toString()
          : null;

      //print('Ruta procesada exitosamente:');
      //print('ID: $nid');
      //print('Título: $title');
      //print('Ubicación: $lat, $lng');
      //print('Distancia: $distance');
      //print('Tiempo: ${hours}h ${minutes}min');
      //print('Elevación: +$positiveElevation, -$negativeElevation');

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
      print('Error procesando ruta:');
      print('Error: $e');
      //print('Stack trace: $stackTrace');
      //print('JSON recibido: $json');
      rethrow;
    }
  }
}
