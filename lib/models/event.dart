class Event {
  final String description;
  final DateTime date;
  final String? link;

  Event({
    required this.description,
    required this.date,
    this.link,
  });
}
