class Category {
  final int tid;
  final String uuid;
  final String name;

  Category({
    required this.tid,
    required this.uuid,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      tid: json['tid'][0]['value'],
      uuid: json['uuid'][0]['value'],
      name: json['name'][0]['value'],
    );
  }
}
