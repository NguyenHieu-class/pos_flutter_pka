/// Model representing a user that can access the POS application.
class User {
  User({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'cashier',
      fullName: json['full_name'] as String?,
      token: token ?? json['token'] as String?,
    );
  }

  final int id;
  final String username;
  final String role;
  final String? fullName;
  final String? token;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'full_name': fullName,
      'token': token,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? role,
    String? fullName,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      token: token ?? this.token,
    );
  }
}
