class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? memberCardNumber;
  final String? profileImage;
  final String? address;
  final DateTime? birthDate;
  final String? baptismDate;
  final String? memberSince;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.memberCardNumber,
    this.profileImage,
    this.address,
    this.birthDate,
    this.baptismDate,
    this.memberSince,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'memberCardNumber': memberCardNumber,
      'profileImage': profileImage,
      'address': address,
      'birthDate': birthDate?.toIso8601String(),
      'baptismDate': baptismDate,
      'memberSince': memberSince,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      memberCardNumber: json['memberCardNumber'],
      profileImage: json['profileImage'],
      address: json['address'],
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate']) 
          : null,
      baptismDate: json['baptismDate'],
      memberSince: json['memberSince'],
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? memberCardNumber,
    String? profileImage,
    String? address,
    DateTime? birthDate,
    String? baptismDate,
    String? memberSince,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberCardNumber: memberCardNumber ?? this.memberCardNumber,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      baptismDate: baptismDate ?? this.baptismDate,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}
