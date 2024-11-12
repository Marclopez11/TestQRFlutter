import 'package:latlong2/latlong.dart';

class Interest {
  final String id;
  final String title;
  final String description;
  final String address;
  final LatLng location;
  final int categoryId;
  final bool featured;
  final String? audioUrl;
  final List<String> imageGallery;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? websiteUrl;
  final String? phoneNumber;
  final String? videoUrl;
  final String mainImage;

  Interest({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.location,
    required this.categoryId,
    required this.featured,
    this.audioUrl,
    required this.imageGallery,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.websiteUrl,
    this.phoneNumber,
    this.videoUrl,
    required this.mainImage,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['nid'][0]['value'].toString(),
      title: json['title'][0]['value'],
      description: json['field_place_description'][0]['value'],
      address: json['field_place_address'][0]['value'],
      location: LatLng(
        double.parse(json['field_place_location'][0]['lat'].toString()),
        double.parse(json['field_place_location'][0]['lng'].toString()),
      ),
      categoryId:
          int.parse(json['field_place_categoria'][0]['target_id'].toString()),
      featured: json['field_place_featured'][0]['value'] ?? false,
      audioUrl: json['field_place_audio'].isNotEmpty
          ? json['field_place_audio'][0]['url']
          : null,
      imageGallery: json['field_place_image_gallery'].isNotEmpty
          ? List<String>.from(
              json['field_place_image_gallery'].map((img) => img['url']))
          : [],
      facebookUrl: json['field_place_facebook'].isNotEmpty
          ? json['field_place_facebook'][0]['value']
          : null,
      instagramUrl: json['field_place_instagram'].isNotEmpty
          ? json['field_place_instagram'][0]['value']
          : null,
      twitterUrl: json['field_place_twitter'].isNotEmpty
          ? json['field_place_twitter'][0]['value']
          : null,
      websiteUrl: json['field_place_web'].isNotEmpty
          ? json['field_place_web'][0]['value']
          : null,
      phoneNumber: json['field_place_phone_number'].isNotEmpty
          ? json['field_place_phone_number'][0]['value']
          : null,
      videoUrl: json['field_place_video'].isNotEmpty
          ? json['field_place_video'][0]['url']
          : null,
      mainImage: json['field_place_main_image'][0]['url'],
    );
  }
}
