import 'package:latlong2/latlong.dart';

class Item {
  final int nid;
  final String uuid;
  final String title;
  final String? address;
  final String? description;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? imageUrl;
  final int? categoryId;
  final LatLng? location;

  Item({
    required this.nid,
    required this.uuid,
    required this.title,
    this.address,
    this.description,
    this.phoneNumber,
    this.email,
    this.website,
    this.imageUrl,
    this.categoryId,
    this.location,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      nid: json['nid'][0]['value'],
      uuid: json['uuid'][0]['value'],
      title: json['title'][0]['value'],
      address: json['field_place_address']?[0]?['value'],
      description: json['field_place_description']?[0]?['value'],
      phoneNumber: json['field_place_phone_number']?[0]?['value'],
      email: json['field_place_email']?[0]?['value'],
      website: json['field_place_web']?[0]?['value'],
      imageUrl: json['field_place_main_image']?[0]?['url'],
      categoryId: json['field_place_categoria']?[0]?['target_id'],
      location: json['field_place_location']?[0]?['value'] != null
          ? _parseLatLng(json['field_place_location'][0]['value'])
          : null,
    );
  }

  static LatLng _parseLatLng(String value) {
    final parts = value.split(',');
    final lat = double.parse(parts[0].trim());
    final lng = double.parse(parts[1].trim());
    return LatLng(lat, lng);
  }
}
