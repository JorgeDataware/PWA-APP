class User {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool mustChangePassword;

  const User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.mustChangePassword = false,
  });

  bool get isAdmin => role == 'Admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    fullName: json['fullName'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.tryParse(json['lastLoginAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  );
}

class LoginResponse {
  final String token;
  final String tokenType;
  final int expiresIn;
  final User user;

  const LoginResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'] as String,
    tokenType: json['tokenType'] as String,
    expiresIn: json['expiresIn'] as int,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}
