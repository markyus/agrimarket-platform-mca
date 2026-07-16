class User {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String location;
  final bool isVerified;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.location,
    required this.isVerified,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'buyer',
      location: json['location'] ?? '',
      isVerified: json['is_verified'] ?? false,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'location': location,
      'is_verified': isVerified,
      'token': token,
    };
  }
}