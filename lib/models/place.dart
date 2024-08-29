import 'package:latlong2/latlong.dart';

class Place {
  final int nid;
  final String uuid;
  final String title;
  final String address;
  final String description;
  final LatLng location;
  final String imageUrl;
  final String phoneNumber;
  final String website;

  Place({
    required this.nid,
    required this.uuid,
    required this.title,
    required this.address,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.phoneNumber,
    required this.website,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      nid: json['nid'][0]['value'],
      uuid: json['uuid'][0]['value'],
      title: json['title'][0]['value'],
      address: json['field_place_address'][0]['value'],
      description: json['field_place_description'][0]['value'],
      location: _parseLocation(json['field_place_location'][0]['value']),
      imageUrl: json['field_place_main_image'][0]['url'],
      phoneNumber: json['field_place_phone_number'][0]['value'],
      website: json['field_place_web'][0]['value'],
    );
  }

  static LatLng _parseLocation(String value) {
    final parts = value.split(',');
    final lat = double.parse(parts[0].trim());
    final lng = double.parse(parts[1].trim());
    return LatLng(lat, lng);
  }
}
