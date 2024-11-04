import 'package:latlong2/latlong.dart';

class MapItem {
  final String id;
  final String title;
  final String description;
  final LatLng position;
  final String imageUrl;
  final int categoryId;
  final String categoryName;
  final double averageRating; // Add this line
  final bool featured;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? websiteUrl;
  final String? whatsappNumber;
  final String? phoneNumber;
  final String? email;
  final int commentCount;

  MapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.averageRating, // Add this line
    this.featured = false,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.websiteUrl,
    this.whatsappNumber,
    this.phoneNumber,
    this.email,
    required this.commentCount,
  });

  factory MapItem.fromJson(Map<String, dynamic> json) {
    return MapItem(
      id: json['uuid'][0]['value'],
      title: json['info'][0]['value'],
      description: json['field_pagina'][0]['value'],
      position: LatLng(0, 0), // Puedes ajustar esto según tus necesidades
      imageUrl: json['field_imatge'][0]['url'],
      categoryId: json['field_ordenacio'][0]['value'],
      categoryName: json['info'][0]['value'],
      averageRating: 0.0, // Puedes ajustar esto según tus necesidades
      commentCount: 0, // Puedes ajustar esto según tus necesidades
    );
  }
}
