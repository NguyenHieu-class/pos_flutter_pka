import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/mysql_service.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  String? _currentTime;
  String? _databaseName;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTime = null;
      _databaseName = null;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final mysqlService = ref.read(mysqlServiceProvider);
      final connection = await mysqlService.connect();

      final results = await connection.query(
        'SELECT NOW() AS current_time, DATABASE() AS db_name',
      );

      if (!mounted) {
        return;
      }

      if (results.isEmpty) {
        const message = 'Query returned no results.';
        setState(() {
          _errorMessage = message;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text(message)),
        );
        return;
      }

      final row = results.first;
      final currentTime = row['current_time'];
      final databaseName = row['db_name'];

      setState(() {
        _currentTime = currentTime?.toString();
        _databaseName = databaseName?.toString();
      });
    } catch (error, stackTrace) {
      debugPrint('Database test failed: $error');
      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      final message = 'Database test failed: $error';
      setState(() {
        _errorMessage = message;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Connection Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _testDatabase,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Test DB'),
            ),
            const SizedBox(height: 24),
            if (_currentTime != null && _databaseName != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Time: $_currentTime'),
                  subtitle: Text('Database: $_databaseName'),
                ),
              )
            else if (_errorMessage != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: const Text('Error'),
                  subtitle: Text(_errorMessage!),
                ),
              )
            else
              const Text('Press the button to test the database connection.'),
          ],
        ),
      ),
    );
  }
}
