import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiBaseUrl = TextEditingController();
  bool _loading = true;
  String _message = '';
  bool _ok = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiBaseUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = await AppScope.of(context).sessionStore.getApiBaseUrl();
    if (!mounted) return;
    setState(() {
      _apiBaseUrl.text = url;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await AppScope.of(context).sessionStore.setApiBaseUrl(_apiBaseUrl.text);
    if (!mounted) return;
    setState(() {
      _ok = true;
      _message = 'Saved. Restart app screens or retry login/chat.';
    });
  }

  Future<void> _test() async {
    await _save();
    final result = await AppScope.of(context).apiClient.health();
    if (!mounted) return;
    setState(() {
      _ok = result.ok;
      _message = result.ok ? 'Backend connected successfully.' : (result.error ?? 'Connection failed.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_message.isNotEmpty && !_ok) AppErrorBox(message: _message),
                  if (_message.isNotEmpty && _ok)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_message),
                    ),
                  TextField(
                    controller: _apiBaseUrl,
                    decoration: const InputDecoration(
                      labelText: 'Backend API base URL',
                      helperText: 'Emulator: http://10.0.2.2:9999 | Real phone: http://YOUR_PC_IP:9999',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _test, icon: const Icon(Icons.wifi_tethering), label: const Text('Save & Test Connection')),
                  const SizedBox(height: 18),
                  Text('Default: ${AppConfig.defaultApiBaseUrl}'),
                ],
              ),
      ),
    );
  }
}
