import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Screen that shows a simple activity log for monitoring admin operations.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final List<_AuditLogEntry> _logs = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedSeverity = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _seedLogs();
  }

  void _seedLogs() {
    final now = DateTime.now();
    _logs.addAll([
      _AuditLogEntry(
        time: now.subtract(const Duration(minutes: 5)),
        severity: 'Thông tin',
        user: 'admin',
        action: 'Đã tạo chương trình khuyến mãi mới',
        module: 'Khuyến mãi',
      ),
      _AuditLogEntry(
        time: now.subtract(const Duration(minutes: 24)),
        severity: 'Cảnh báo',
        user: 'manager',
        action: 'Đăng nhập thất bại 3 lần',
        module: 'Bảo mật',
      ),
      _AuditLogEntry(
        time: now.subtract(const Duration(hours: 3)),
        severity: 'Lỗi',
        user: 'service',
        action: 'Không kết nối được tới dịch vụ thanh toán',
        module: 'Hệ thống',
      ),
      _AuditLogEntry(
        time: now.subtract(const Duration(days: 1, hours: 4)),
        severity: 'Thông tin',
        user: 'auditor',
        action: 'Xuất báo cáo doanh thu',
        module: 'Báo cáo',
      ),
    ]);
  }

  List<_AuditLogEntry> get _filteredLogs {
    final severity = _selectedSeverity;
    final keyword = _searchController.text.trim().toLowerCase();
    return _logs.where((log) {
      final matchSeverity = severity == 'Tất cả' || log.severity == severity;
      final matchKeyword = keyword.isEmpty ||
          log.user.toLowerCase().contains(keyword) ||
          log.action.toLowerCase().contains(keyword) ||
          log.module.toLowerCase().contains(keyword);
      return matchSeverity && matchKeyword;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký & giám sát'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm theo người dùng, hành động, module',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Mức độ:', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedSeverity,
                      items: const [
                        DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'Thông tin', child: Text('Thông tin')),
                        DropdownMenuItem(value: 'Cảnh báo', child: Text('Cảnh báo')),
                        DropdownMenuItem(value: 'Lỗi', child: Text('Lỗi')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSeverity = value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(
                    child: Text('Không có sự kiện nào phù hợp với bộ lọc hiện tại.'),
                  )
                : ListView.separated(
                    itemCount: _filteredLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return ListTile(
                        leading: Icon(log.icon, color: log.color(theme.colorScheme)),
                        title: Text(log.action),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(log.time)} • '
                          '${log.user} • ${log.module}',
                        ),
                        trailing: Text(
                          log.severity,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: log.color(theme.colorScheme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogEntry {
  _AuditLogEntry({
    required this.time,
    required this.severity,
    required this.user,
    required this.action,
    required this.module,
  });

  final DateTime time;
  final String severity;
  final String user;
  final String action;
  final String module;

  IconData get icon {
    switch (severity) {
      case 'Lỗi':
        return Icons.error_outline;
      case 'Cảnh báo':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color color(ColorScheme scheme) {
    switch (severity) {
      case 'Lỗi':
        return scheme.error;
      case 'Cảnh báo':
        return scheme.tertiary;
      default:
        return scheme.primary;
    }
  }
}
