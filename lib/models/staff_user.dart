/// Representation of cashier or kitchen staff accounts that can be managed by
/// the admin panel.
class StaffUser {
  StaffUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    this.phone,
    this.email,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'cashier',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          '${json['is_active']}' == '1',
    );
  }

  final int id;
  final String name;
  final String username;
  final String role;
  final bool isActive;
  final String? phone;
  final String? email;

  StaffUser copyWith({
    int? id,
    String? name,
    String? username,
    String? role,
    bool? isActive,
    String? phone,
    String? email,
  }) {
    return StaffUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
