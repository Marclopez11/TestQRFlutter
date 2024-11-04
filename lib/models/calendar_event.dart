import 'package:latlong2/latlong.dart';

class CalendarEvent {
  final String title;
  final String langcode;
  final DateTime date;
  final String shortDescription;
  final String longDescription;
  final bool featured;
  final String link;
  final List<String> imageGallery;
  final String? mainImage;
  final LatLng? location;

  CalendarEvent({
    required this.title,
    required this.langcode,
    required this.date,
    required this.shortDescription,
    required this.longDescription,
    required this.featured,
    required this.link,
    required this.imageGallery,
    this.mainImage,
    this.location,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title']?[0]?['value'] ?? '',
      langcode: json['langcode']?[0]?['value'] ?? '',
      date: json['field_calendar_date']?[0]?['value'] != null
          ? DateTime.parse(json['field_calendar_date'][0]['value'])
          : DateTime.now(),
      shortDescription:
          json['field_calendar_short_description']?[0]?['value'] ?? '',
      longDescription:
          json['field_calendar_long_description']?[0]?['value'] ?? '',
      featured: json['field_calendar_featured']?[0]?['value'] == '1',
      link: json['field_calendar_link']?.isNotEmpty == true
          ? json['field_calendar_link'][0]['value']
          : '',
      imageGallery: json['field_calendar_image_gallery'] != null
          ? List<String>.from(json['field_calendar_image_gallery']
              .map((image) => image['url'] ?? ''))
          : [],
      mainImage: json['field_calendar_main_image']?.isNotEmpty == true
          ? json['field_calendar_main_image'][0]['url']
          : null,
      location: json['field_calendar_location']?.isNotEmpty == true
          ? _parseLocation(json['field_calendar_location'][0]['value'])
          : null,
    );
  }

  static LatLng? _parseLocation(String value) {
    final parts = value.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }
}
