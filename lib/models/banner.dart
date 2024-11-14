import 'package:intl/intl.dart';

class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final DateTime expirationDate;
  final DateTime publicationDate;
  final String? webLink;
  final String langcode;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.expirationDate,
    required this.publicationDate,
    required this.langcode,
    this.webLink,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    try {
      return BannerModel(
        id: json['nid'][0]['value'],
        title: json['title'][0]['value'],
        imageUrl: json['field_imatge'][0]['url'],
        expirationDate:
            DateTime.parse(json['field_data_caducitat'][0]['value']),
        publicationDate:
            DateTime.parse(json['field_data_publicacio'][0]['value']),
        langcode: json['langcode'][0]['value'],
        webLink: json['field_enllac_web']?.isNotEmpty == true
            ? json['field_enllac_web'][0]['value']
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing banner: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  bool get isExpired {
    final now = DateTime.now();
    return expirationDate.isBefore(now);
  }

  bool get isPublished {
    final now = DateTime.now();
    return publicationDate.isBefore(now) ||
        publicationDate.isAtSameMomentAs(now);
  }

  bool get isActive => isPublished && !isExpired;
}
