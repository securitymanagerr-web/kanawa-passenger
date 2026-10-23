// KANAWA - Modelo de Utilizador

class User {
  final String id;
  final String phone;
  final String? email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? profilePhoto;
  final int userType;
  final String userTypeDisplay;
  final bool isVerified;
  final String country;
  final String province;
  final String municipality;

  User({
    required this.id,
    required this.phone,
    this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.profilePhoto,
    required this.userType,
    required this.userTypeDisplay,
    required this.isVerified,
    required this.country,
    required this.province,
    required this.municipality,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      profilePhoto: json['profile_photo'],
      userType: json['user_type'] ?? 0,
      userTypeDisplay: json['user_type_display'] ?? '',
      isVerified: json['is_verified'] ?? false,
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      municipality: json['municipality'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'profile_photo': profilePhoto,
        'user_type': userType,
        'user_type_display': userTypeDisplay,
        'is_verified': isVerified,
        'country': country,
        'province': province,
        'municipality': municipality,
      };

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  bool get isPassenger => userType == 20;
  bool get isDriver => userType == 10;
}