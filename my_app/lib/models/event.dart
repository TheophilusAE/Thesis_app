class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final String? qrCode;
  bool isAttended;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    this.qrCode,
    this.isAttended = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      qrCode: json['qrCode'],
      isAttended: json['isAttended'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'qrCode': qrCode,
      'isAttended': isAttended,
    };
  }
}
