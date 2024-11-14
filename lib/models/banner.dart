import 'package:intl/intl.dart';
import 'package:felanitx/models/calendar_event.dart';
import 'package:felanitx/models/interest.dart';

class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final DateTime expirationDate;
  final DateTime publicationDate;
  final String? webLink;
  final String langcode;
  final String type;
  final CalendarEvent? originalEvent;
  final Interest? originalInterest;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.expirationDate,
    required this.publicationDate,
    required this.langcode,
    required this.type,
    this.webLink,
    this.originalEvent,
    this.originalInterest,
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
        type: 'banner',
        webLink: json['field_enllac_web']?.isNotEmpty == true
            ? json['field_enllac_web'][0]['value']
            : null,
      );
    } catch (e) {
      print('Error parsing banner: $e');
      rethrow;
    }
  }

  factory BannerModel.fromEvent(CalendarEvent event) {
    return BannerModel(
      id: 0,
      title: event.title,
      imageUrl: event.mainImage ?? '',
      expirationDate:
          event.expirationDate ?? DateTime.now().add(Duration(days: 1)),
      publicationDate: event.date,
      langcode: event.langcode,
      type: 'event',
      webLink: event.link,
      originalEvent: event,
    );
  }

  factory BannerModel.fromInterest(Interest interest) {
    return BannerModel(
      id: int.parse(interest.id),
      title: interest.title,
      imageUrl: interest.mainImage,
      expirationDate: DateTime.now().add(Duration(days: 365)),
      publicationDate: DateTime.now(),
      langcode: interest.langcode,
      type: 'interest',
      webLink: interest.websiteUrl,
      originalInterest: interest,
    );
  }

  bool get isPublished {
    final now = DateTime.now();
    if (type == 'event') {
      return true;
    }
    return publicationDate.isBefore(now) ||
        publicationDate.isAtSameMomentAs(now);
  }

  bool get isExpired {
    final now = DateTime.now();
    if (type == 'event') {
      return expirationDate.isBefore(now);
    }
    return expirationDate.isBefore(now);
  }

  bool get isActive {
    return isPublished && !isExpired;
  }
}
