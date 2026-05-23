class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> roles; // Multiple roles per user (e.g., ['jemaat', 'pelayan'])
  final String membershipStatus;
  final String? identityNumber;
  final String? familyGroup;
  final String? membershipType;
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
    this.roles = const ['jemaat'], // Default to jemaat role
    this.membershipStatus = 'pending',
    this.identityNumber,
    this.familyGroup,
    this.membershipType,
    this.memberCardNumber,
    this.profileImage,
    this.address,
    this.birthDate,
    this.baptismDate,
    this.memberSince,
  });

  /// Check if user has a specific role
  bool hasRole(String role) => roles.contains(role);

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> checkRoles) => 
      checkRoles.any((r) => roles.contains(r));

  /// Check if user is admin
  bool get isAdmin => hasRole('admin');

  /// Check if user is pelayan
  bool get isPelayan => hasRole('pelayan');

  /// Check if user is jemaat
  bool get isJemaat => hasRole('jemaat');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'membershipStatus': membershipStatus,
      'identityNumber': identityNumber,
      'familyGroup': familyGroup,
      'membershipType': membershipType,
      'memberCardNumber': memberCardNumber,
      'profileImage': profileImage,
      'address': address,
      'birthDate': birthDate?.toIso8601String(),
      'baptismDate': baptismDate,
      'memberSince': memberSince,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both old single 'role' format and new 'roles' format for backward compatibility
    List<String> userRoles = const ['jemaat'];
    
    if (json['roles'] != null && json['roles'] is List) {
      userRoles = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      // Backward compatibility: convert single role to list
      userRoles = [json['role'] as String];
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      roles: userRoles,
      membershipStatus: json['membershipStatus'] ?? 'pending',
      identityNumber: json['identityNumber'],
      familyGroup: json['familyGroup'],
      membershipType: json['membershipType'],
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
    List<String>? roles,
    String? membershipStatus,
    String? identityNumber,
    String? familyGroup,
    String? membershipType,
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
      roles: roles ?? this.roles,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      identityNumber: identityNumber ?? this.identityNumber,
      familyGroup: familyGroup ?? this.familyGroup,
      membershipType: membershipType ?? this.membershipType,
      memberCardNumber: memberCardNumber ?? this.memberCardNumber,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      baptismDate: baptismDate ?? this.baptismDate,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}
