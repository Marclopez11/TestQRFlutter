class Category {
  final String id;
  final String title;
  final String imageUrl;
  final String page;

  Category({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.page,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['uuid'][0]['value'],
      title: json['info'][0]['value'],
      imageUrl: json['field_imatge'][0]['url'],
      page: json['field_pagina'][0]['value'],
    );
  }
}
