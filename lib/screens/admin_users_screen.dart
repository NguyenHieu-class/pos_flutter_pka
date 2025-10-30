import 'package:flutter/material.dart';

import '../models/staff_user.dart';
import '../services/api_service.dart';
import '../services/user_management_service.dart';

/// Screen allowing admins to manage cashier and kitchen user accounts.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = UserManagementService.instance;
  late Future<List<StaffUser>> _usersFuture;
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final roles = _roleFilter == 'all' ? null : <String>[_roleFilter];
    setState(() {
      _usersFuture = _service.fetchStaff(roles: roles);
    });
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'cashier':
        return 'Thu ngân';
      case 'kitchen':
        return 'Bếp';
      default:
        return role;
    }
  }

  Future<void> _showUserDialog({StaffUser? user}) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    String selectedRole = user?.role ?? 'cashier';
    bool isActive = user?.isActive ?? true;

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(user == null ? 'Thêm người dùng' : 'Chỉnh sửa người dùng'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên hiển thị';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên đăng nhập';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: user == null ? 'Mật khẩu' : 'Mật khẩu (để trống nếu không đổi)',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (user == null && (value == null || value.isEmpty)) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'cashier', child: Text('Thu ngân')),
                          DropdownMenuItem(value: 'kitchen', child: Text('Bếp')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() {
                            selectedRole = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Vai trò'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hoạt động'),
                        value: isActive,
                        onChanged: (value) {
                          setStateDialog(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setStateDialog(() => isSubmitting = true);
                          try {
                            if (user == null) {
                              await _service.createStaff(
                                name: nameController.text.trim(),
                                username: usernameController.text.trim(),
                                password: passwordController.text,
                                role: selectedRole,
                                phone: phoneController.text.trim(),
                                email: emailController.text.trim(),
                                isActive: isActive,
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Đã tạo người dùng mới')),
                              );
                            } else {
                              await _service.updateStaff(
                                id: user.id,
                                name: nameController.text.trim(),
                                username: usernameController.text.trim(),
                                role: selectedRole,
                                password: passwordController.text,
                                phone: phoneController.text.trim(),
                                email: emailController.text.trim(),
                                isActive: isActive,
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Đã cập nhật người dùng')),
                              );
                            }
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } on ApiException catch (error) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                            setStateDialog(() => isSubmitting = false);
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Không thể lưu người dùng: $error')),
                            );
                            setStateDialog(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(user == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldReload == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(StaffUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa người dùng'),
          content: Text('Bạn có chắc muốn xóa "${user.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _service.deleteStaff(user.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã xóa người dùng')), 
        );
        _loadUsers();
      } on ApiException catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Không thể xóa người dùng: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')), 
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Thêm người dùng'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Lọc vai trò:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _roleFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _roleFilter = value;
                    });
                    _loadUsers();
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'cashier', child: Text('Thu ngân')),
                    DropdownMenuItem(value: 'kitchen', child: Text('Bếp')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadUsers();
                await _usersFuture;
              },
              child: FutureBuilder<List<StaffUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Lỗi: ${snapshot.error}'),
                        ),
                      ],
                    );
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('Chưa có người dùng phù hợp.')),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final chipColor = user.isActive
                          ? Colors.green.shade100
                          : Colors.orange.shade100;
                      return Card(
                        child: ListTile(
                          title: Text(user.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Tên đăng nhập: ${user.username}'),
                              Text('Vai trò: ${_roleLabel(user.role)}'),
                              if (user.phone != null && user.phone!.isNotEmpty)
                                Text('Điện thoại: ${user.phone}'),
                              if (user.email != null && user.email!.isNotEmpty)
                                Text('Email: ${user.email}'),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(user.isActive ? 'Hoạt động' : 'Ngưng'),
                                backgroundColor: chipColor,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showUserDialog(user: user);
                              } else if (value == 'delete') {
                                _deleteUser(user);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Chỉnh sửa'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Xóa'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: users.length,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
