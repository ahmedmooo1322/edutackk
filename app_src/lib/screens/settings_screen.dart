import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../i18n/app_strings.dart';
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
  String _language = 'ar';

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
    final scope = AppScope.of(context);
    final url = await scope.sessionStore.getApiBaseUrl();
    final lang = await scope.sessionStore.getLanguageCode();
    if (!mounted) return;
    setState(() {
      _apiBaseUrl.text = url;
      _language = lang;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final scope = AppScope.of(context);
    await scope.sessionStore.setApiBaseUrl(_apiBaseUrl.text);
    await scope.setLanguage(_language);
    if (!mounted) return;
    setState(() {
      _ok = true;
      _message = context.tr('saved');
    });
  }

  Future<void> _test() async {
    await _save();
    final result = await AppScope.of(context).apiClient.health();
    if (!mounted) return;
    setState(() {
      _ok = result.ok;
      _message = result.ok ? context.tr('backendConnected') : (result.error ?? 'Connection failed.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
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
                  DropdownButtonFormField<String>(
                    value: _language,
                    decoration: InputDecoration(labelText: context.tr('language')),
                    items: [
                      DropdownMenuItem(value: 'ar', child: Text(context.tr('arabic'))),
                      DropdownMenuItem(value: 'en', child: Text(context.tr('english'))),
                    ],
                    onChanged: (value) => setState(() => _language = value ?? 'ar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiBaseUrl,
                    decoration: InputDecoration(
                      labelText: context.tr('backendUrl'),
                      helperText: 'Default: ${AppConfig.defaultApiBaseUrl}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _test, icon: const Icon(Icons.wifi_tethering), label: Text(context.tr('saveTest'))),
                ],
              ),
      ),
    );
  }
}
