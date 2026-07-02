import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiBaseUrl = TextEditingController(text: AppConfig.defaultApiBaseUrl);
  final _adminPassword = TextEditingController();
  bool _loading = false;
  String _message = '';
  bool _ok = true;
  String _language = 'ar';
  bool _darkMode = false;
  bool _adminUnlocked = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(AppScope.of(context));
  }

  @override
  void dispose() {
    _apiBaseUrl.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  Future<void> _load(AppScope scope) async {
    try {
      final url = await scope.sessionStore.getApiBaseUrl();
      final lang = await scope.sessionStore.getLanguageCode();
      final dark = await scope.sessionStore.getDarkMode();
      if (!mounted) return;
      setState(() {
        _apiBaseUrl.text = url;
        _language = lang;
        _darkMode = dark;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _message = '${context.tr('settingsLoadFailed')}: $e';
      });
    }
  }

  Future<void> _saveBasic() async {
    final scope = AppScope.of(context);
    await scope.setLanguage(_language);
    await scope.setDarkMode(_darkMode);
    if (!mounted) return;
    setState(() {
      _ok = true;
      _message = context.tr('saved');
    });
  }

  Future<void> _unlockAdmin() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    final result = await AppScope.of(context).apiClient.verifyAdminKey(_adminPassword.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _ok = result.ok;
      _adminUnlocked = result.ok;
      _message = result.ok ? context.tr('saved') : (result.error ?? 'Wrong password');
    });
  }

  Future<void> _saveApiAndTest() async {
    final scope = AppScope.of(context);
    await scope.sessionStore.setApiBaseUrl(_apiBaseUrl.text);
    await _saveBasic();
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await AppScope.of(context).apiClient.health();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _ok = result.ok;
      _message = result.ok ? context.tr('backendConnected') : (result.error ?? 'Connection failed.');
    });
  }

  Widget _content(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (_message.isNotEmpty && !_ok) AppErrorBox(message: _message),
        if (_message.isNotEmpty && _ok)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('darkMode')),
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
        FilledButton.icon(onPressed: _saveBasic, icon: const Icon(Icons.save), label: Text(context.tr('saveOnly'))),
        const SizedBox(height: 24),
        Text(context.tr('adminSettings'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (!_adminUnlocked) ...[
          Text(context.tr('apiLocked')),
          const SizedBox(height: 12),
          TextField(controller: _adminPassword, obscureText: true, decoration: InputDecoration(labelText: context.tr('adminPassword'))),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _unlockAdmin,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_open),
            label: Text(context.tr('unlock')),
          ),
        ],
        if (_adminUnlocked) ...[
          TextField(
            controller: _apiBaseUrl,
            decoration: InputDecoration(labelText: context.tr('backendUrl'), helperText: 'Default: ${AppConfig.defaultApiBaseUrl}'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _saveApiAndTest,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
            label: Text(_loading ? context.tr('testing') : context.tr('saveTest')),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return Scaffold(appBar: AppBar(title: Text(context.tr('settings'))), body: SafeArea(child: _content(context)));
  }
}
