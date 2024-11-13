class HotelService {
  final int id;
  final String name;

  HotelService({required this.id, required this.name});

  factory HotelService.fromJson(Map<String, dynamic> json) {
    return HotelService(
      id: json['tid'][0]['value'],
      name: json['name'][0]['value'],
    );
  }
}
