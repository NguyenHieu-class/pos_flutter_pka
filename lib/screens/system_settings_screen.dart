import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_service.dart';

/// Screen that exposes a couple of system level toggles and a connectivity check.
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _autoSync = true;
  bool _enableNotifications = true;
  bool _maintenanceMode = false;
  bool _checkingConnection = false;
  String? _lastCheckResult;

  Future<void> _checkConnection() async {
    setState(() {
      _checkingConnection = true;
      _lastCheckResult = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await ApiService.instance.get('/health', auth: false);
      setState(() {
        _lastCheckResult = 'Kết nối thành công: ${response ?? 'API phản hồi'}';
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã kết nối tới máy chủ thành công.')),
      );
    } on ApiException catch (error) {
      setState(() {
        _lastCheckResult = 'API trả về lỗi: ${error.message}';
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Không kết nối được tới API: ${error.message}')),
      );
    } catch (error) {
      setState(() {
        _lastCheckResult = 'Lỗi: $error';
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể kiểm tra kết nối: $error')),
      );
    } finally {
      setState(() {
        _checkingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tuỳ chọn vận hành', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Tự động đồng bộ dữ liệu'),
            subtitle: const Text('Đảm bảo dữ liệu quầy và máy chủ luôn khớp.'),
            value: _autoSync,
            onChanged: (value) => setState(() => _autoSync = value),
          ),
          SwitchListTile(
            title: const Text('Gửi thông báo hệ thống'),
            subtitle: const Text('Nhận cảnh báo khi có sự cố quan trọng.'),
            value: _enableNotifications,
            onChanged: (value) => setState(() => _enableNotifications = value),
          ),
          SwitchListTile(
            title: const Text('Chế độ bảo trì'),
            subtitle: const Text('Tạm dừng nhận order từ nhân viên và ứng dụng khách.'),
            value: _maintenanceMode,
            onChanged: (value) => setState(() => _maintenanceMode = value),
          ),
          const Divider(height: 32),
          Text('Thông tin kết nối', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API base: $apiBase'),
                  Text('Phiên bản API: $apiVersionPath'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _checkingConnection ? null : _checkConnection,
                    icon: _checkingConnection
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: Text(_checkingConnection ? 'Đang kiểm tra...' : 'Kiểm tra kết nối'),
                  ),
                  if (_lastCheckResult != null) ...[
                    const SizedBox(height: 12),
                    Text(_lastCheckResult!),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Text('Nhật ký cấu hình', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Tự động đồng bộ: ${_autoSync ? 'Bật' : 'Tắt'}'),
                  Text('• Thông báo hệ thống: ${_enableNotifications ? 'Bật' : 'Tắt'}'),
                  Text('• Chế độ bảo trì: ${_maintenanceMode ? 'Bật' : 'Tắt'}'),
                  if (_lastCheckResult != null) Text('• Lần kiểm tra gần nhất: $_lastCheckResult'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
