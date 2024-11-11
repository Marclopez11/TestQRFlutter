import 'package:latlong2/latlong.dart';

class Population {
  final String id;
  final String title;
  final String? title1;
  final String? title2;
  final String? title3;
  final String? description1;
  final String? description2;
  final String? description3;
  final String mainImage;
  final List<String> imageGallery;
  final LatLng location;

  Population({
    required this.id,
    required this.title,
    this.title1,
    this.title2,
    this.title3,
    this.description1,
    this.description2,
    this.description3,
    required this.mainImage,
    required this.imageGallery,
    required this.location,
  });

  factory Population.fromJson(Map<String, dynamic> json) {
    return Population(
      id: json['uuid'][0]['value'],
      title: json['title'][0]['value'],
      title1: json['field_population_title1']?.isNotEmpty == true
          ? json['field_population_title1'][0]['value']
          : null,
      title2: json['field_population_title2']?.isNotEmpty == true
          ? json['field_population_title2'][0]['value']
          : null,
      title3: json['field_population_title3']?.isNotEmpty == true
          ? json['field_population_title3'][0]['value']
          : null,
      description1: json['field_population_description1']?.isNotEmpty == true
          ? json['field_population_description1'][0]['value']
          : null,
      description2: json['field_population_description2']?.isNotEmpty == true
          ? json['field_population_description2'][0]['value']
          : null,
      description3: json['field_population_description3']?.isNotEmpty == true
          ? json['field_population_description3'][0]['value']
          : null,
      mainImage: json['field_population_main_image'][0]['url'],
      imageGallery: (json['field_population_image_gallery'] as List<dynamic>)
          .map((image) => image['url'] as String)
          .toList(),
      location: _parseLocation(json['field_population_location'][0]['value']),
    );
  }

  static LatLng _parseLocation(String value) {
    final parts = value.split(',');
    final lat = double.parse(parts[0].trim());
    final lng = double.parse(parts[1].trim());
    return LatLng(lat, lng);
  }
}
