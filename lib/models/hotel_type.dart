class HotelType {
  final int id;
  final String name;

  HotelType({required this.id, required this.name});

  factory HotelType.fromJson(Map<String, dynamic> json) {
    return HotelType(
      id: json['tid'][0]['value'],
      name: json['name'][0]['value'],
    );
  }
}
