import 'package:latlong2/latlong.dart';

class Accommodation {
  final String id;
  final String title;
  final String description;
  final String mainImage;
  final LatLng location;
  final int hotelType;
  final List<int> hotelServices;
  final String? web;
  final String? twitter;
  final String? instagram;
  final String? facebook;
  final String address;
  final String phoneNumber;
  final String? phoneNumber2;
  final String email;
  final List<String> imageGallery;
  final String? stars;
  final int categoryId;

  Accommodation({
    required this.id,
    required this.title,
    required this.description,
    required this.mainImage,
    required this.location,
    required this.hotelType,
    required this.hotelServices,
    this.web,
    this.twitter,
    this.instagram,
    this.facebook,
    required this.address,
    required this.phoneNumber,
    this.phoneNumber2,
    required this.email,
    required this.imageGallery,
    this.stars,
    required this.categoryId,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    try {
      return Accommodation(
        id: json['nid'][0]['value'].toString(),
        title: json['title'][0]['value'],
        description: json['field_hotel_description'][0]['value'],
        mainImage: json['field_hotel_main_image'][0]['url'],
        location: LatLng(
          json['field_hotel_location'][0]['lat'],
          json['field_hotel_location'][0]['lng'],
        ),
        hotelType: json['field_hotel_hoteltype'][0]['target_id'],
        hotelServices: List<int>.from(
          json['field_hotel_hotelservices']
              .map((service) => service['target_id']),
        ),
        web: json['field_hotel_web']?.isNotEmpty == true
            ? json['field_hotel_web'][0]['value']
            : null,
        twitter: json['field_hotel_twitter']?.isNotEmpty == true
            ? json['field_hotel_twitter'][0]['value']
            : null,
        instagram: json['field_hotel_instagram']?.isNotEmpty == true
            ? json['field_hotel_instagram'][0]['value']
            : null,
        facebook: json['field_hotel_facebook']?.isNotEmpty == true
            ? json['field_hotel_facebook'][0]['value']
            : null,
        address: json['field_hotel_address'][0]['value'],
        phoneNumber: json['field_hotel_phone_number'][0]['value'].toString(),
        phoneNumber2: json['field_hotel_phone_number2']?.isNotEmpty == true
            ? json['field_hotel_phone_number2'][0]['value'].toString()
            : null,
        email: json['field_hotel_email']?.isNotEmpty == true
            ? json['field_hotel_email'][0]['value']
            : '',
        imageGallery: json['field_hotel_image_gallery']?.isNotEmpty == true
            ? List<String>.from(
                json['field_hotel_image_gallery'].map((image) => image['url']),
              )
            : [],
        stars: json['field_hotel_stars']?.isNotEmpty == true
            ? json['field_hotel_stars'][0]['value']
            : null,
        categoryId: json['field_hotel_hoteltype'][0]['target_id'],
      );
    } catch (e, stackTrace) {
      print('Error parsing accommodation: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
