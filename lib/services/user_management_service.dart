import '../models/staff_user.dart';
import 'api_service.dart';

/// Service dedicated to admin-only user management actions.
class UserManagementService {
  UserManagementService._();

  static final UserManagementService instance = UserManagementService._();

  final ApiService _api = ApiService.instance;

  Future<List<StaffUser>> fetchStaff({List<String>? roles}) async {
    final response = await _api.get(
      '/admin/users',
      query: roles == null || roles.isEmpty
          ? null
          : {
              'role': roles.join(','),
            },
    );
    if (response is List) {
      return response
          .map((user) => StaffUser.fromJson(user as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không lấy được danh sách người dùng');
  }

  Future<StaffUser> createStaff({
    required String name,
    required String username,
    required String password,
    required String role,
    String? phone,
    String? email,
    bool isActive = true,
  }) async {
    final response = await _api.post('/admin/users', {
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'is_active': isActive ? 1 : 0,
    });
    if (response is Map<String, dynamic>) {
      return StaffUser.fromJson(response);
    }
    throw ApiException('Không thể tạo người dùng mới');
  }

  Future<StaffUser> updateStaff({
    required int id,
    required String name,
    required String username,
    required String role,
    String? password,
    String? phone,
    String? email,
    bool isActive = true,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'username': username,
      'role': role,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'is_active': isActive ? 1 : 0,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    final response = await _api.put('/admin/users/$id', body);
    if (response is Map<String, dynamic>) {
      return StaffUser.fromJson(response);
    }
    throw ApiException('Không thể cập nhật người dùng');
  }

  Future<void> deleteStaff(int id) async {
    await _api.delete('/admin/users/$id');
  }
}
