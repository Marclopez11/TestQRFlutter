import 'package:uuid/uuid.dart';

class PlanItem {
  final String id;
  final String title;
  final String type; // 'event', 'interest', 'accommodation', etc.
  final String imageUrl;
  final DateTime? plannedDate;
  final String? notes;
  final Map<String, dynamic> originalItem;

  PlanItem({
    String? id,
    required this.title,
    required this.type,
    required this.imageUrl,
    this.plannedDate,
    this.notes,
    required this.originalItem,
  }) : id = id ?? const Uuid().v4();

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      imageUrl: json['imageUrl'],
      plannedDate: json['plannedDate'] != null
          ? DateTime.parse(json['plannedDate'])
          : null,
      notes: json['notes'],
      originalItem: json['originalItem'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'imageUrl': imageUrl,
      'plannedDate': plannedDate?.toIso8601String(),
      'notes': notes,
      'originalItem': originalItem,
    };
  }

  PlanItem copyWith({
    String? title,
    String? type,
    String? imageUrl,
    DateTime? plannedDate,
    String? notes,
    Map<String, dynamic>? originalItem,
  }) {
    return PlanItem(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      plannedDate: plannedDate ?? this.plannedDate,
      notes: notes ?? this.notes,
      originalItem: originalItem ?? this.originalItem,
    );
  }
}
