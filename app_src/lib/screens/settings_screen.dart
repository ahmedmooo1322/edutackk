import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _role = 'student';
  bool _darkMode = false;
  bool _adminUnlocked = false;
  bool _started = false;
  bool _whatsappEnabled = false;
  String _whatsappNumber = '';
  String _whatsappMessageEn = 'Hello admin, I want to activate my EduTrack account.';
  String _whatsappMessageAr = 'مرحباً، أريد تفعيل حساب EduTrack الخاص بي.';

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
      final summary = await scope.sessionStore.getUserSummary();
      final appSettings = await scope.apiClient.publicAppSettings();
      final whatsapp = (appSettings.data?['settings'] as Map<String, dynamic>?)?['activation_whatsapp'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _apiBaseUrl.text = url;
        _language = lang;
        _role = (summary['role'] ?? 'student').trim();
        _darkMode = dark;
        _whatsappEnabled = whatsapp?['enabled'] == true;
        _whatsappNumber = whatsapp?['number']?.toString() ?? '';
        _whatsappMessageEn = whatsapp?['message_en']?.toString() ?? _whatsappMessageEn;
        _whatsappMessageAr = whatsapp?['message_ar']?.toString() ?? _whatsappMessageAr;
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

  Future<void> _contactAdminWhatsapp() async {
    final number = _whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (!_whatsappEnabled || number.isEmpty) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _message = context.tr('whatsappUnavailable');
      });
      return;
    }
    final lang = AppScope.of(context).languageCode;
    final message = lang == 'en' ? _whatsappMessageEn : _whatsappMessageAr;
    final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      setState(() {
        _ok = false;
        _message = context.tr('whatsappOpenFailed');
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('logoutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('logout'))),
        ],
      ),
    );
    if (confirm != true) return;
    await AppScope.of(context).apiClient.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _switchAdminMode(String mode) async {
    await AppScope.of(context).sessionStore.setAdminPreferredMode(mode);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(mode == 'admin' ? '/admin' : '/home', (_) => false);
  }

  Future<void> _requestAccountDeletion() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('requestAccountDeletion')),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: context.tr('reportReason')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(context.tr('sendRequest'))),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    final result = await AppScope.of(context).apiClient.requestAccountDeletion(reason);
    if (!mounted) return;
    setState(() {
      _ok = result.ok;
      _message = result.ok ? context.tr('accountDeletionRequestSent') : (result.error ?? context.tr('connectionProblem'));
    });
  }

  Widget _content(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: [
        if (_message.isNotEmpty && !_ok) AppErrorBox(message: _message),
        if (_message.isNotEmpty && _ok)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(_message),
          ),
        _section(
          context,
          title: context.tr('account'),
          children: [
            _tile(Icons.person_outline, context.tr('profile'), context.tr('profileSubtitle'), () => Navigator.pushNamed(context, '/profile')),
            _tile(Icons.workspace_premium_outlined, context.tr('subscription'), context.tr('subscriptionSubtitle'), () => Navigator.pushNamed(context, '/subscription')),
            _tile(Icons.delete_outline, context.tr('requestAccountDeletion'), context.tr('accountDeletionHint'), _requestAccountDeletion),
          ],
        ),
        _section(
          context,
          title: context.tr('privacySafety'),
          children: [
            _tile(Icons.block, context.tr('blockedUsers'), context.tr('blockedUsersHint'), () => Navigator.pushNamed(context, '/blocked-users')),
            _tile(Icons.mark_email_unread_outlined, context.tr('messageRequests'), context.tr('messageRequestInfo'), () => Navigator.pushNamed(context, '/message-requests')),
            if (_whatsappEnabled && _whatsappNumber.isNotEmpty) _tile(Icons.chat, context.tr('contactAdminActivation'), context.tr('whatsappActivationHint'), _contactAdminWhatsapp),
          ],
        ),
        _section(
          context,
          title: context.tr('appSection'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _language,
                decoration: InputDecoration(labelText: context.tr('language')),
                items: [
                  DropdownMenuItem(value: 'ar', child: Text(context.tr('arabic'))),
                  DropdownMenuItem(value: 'en', child: Text(context.tr('english'))),
                ],
                onChanged: (value) => setState(() => _language = value ?? 'ar'),
              ),
            ),
            SwitchListTile(
              title: Text(context.tr('darkMode')),
              value: _darkMode,
              onChanged: (value) async {
                setState(() => _darkMode = value);
                await AppScope.of(context).setDarkMode(value);
              },
            ),
            _tile(Icons.system_update_alt, context.tr('checkForUpdate'), context.tr('checkForUpdateHint'), () => Navigator.pushNamed(context, '/update-check')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FilledButton.icon(onPressed: _saveBasic, icon: const Icon(Icons.save), label: Text(context.tr('saveOnly'))),
            ),
          ],
        ),
        if (_role == 'admin')
          _section(
            context,
            title: context.tr('adminTools'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(context.tr('adminSwitchHelp'), style: Theme.of(context).textTheme.bodySmall),
              ),
              _tile(Icons.admin_panel_settings, context.tr('switchToAdminMode'), context.tr('adminDashboardSubtitle'), () => _switchAdminMode('admin')),
              _tile(Icons.chat_bubble_outline, context.tr('switchToNormalMode'), context.tr('adminSupportModeHint'), () => _switchAdminMode('normal')),
            ],
          ),
        _section(
          context,
          title: context.tr('adminSettings'),
          children: [
            if (!_adminUnlocked) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(context.tr('apiLocked')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(controller: _adminPassword, obscureText: true, decoration: InputDecoration(labelText: context.tr('adminPassword'))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: FilledButton.icon(
                  onPressed: _loading ? null : _unlockAdmin,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_open),
                  label: Text(context.tr('unlock')),
                ),
              ),
            ],
            if (_adminUnlocked) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _apiBaseUrl,
                  decoration: InputDecoration(labelText: context.tr('backendUrl'), helperText: 'Default: ${AppConfig.defaultApiBaseUrl}'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: FilledButton.icon(
                  onPressed: _loading ? null : _saveApiAndTest,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
                  label: Text(_loading ? context.tr('testing') : context.tr('saveTest')),
                ),
              ),
            ],
          ],
        ),
        _section(
          context,
          title: context.tr('about'),
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.tr('appVersion')),
              subtitle: const Text('${AppConfig.appVersionName}+${AppConfig.appBuildNumber}'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.tr('developerCredit'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
        _section(
          context,
          title: context.tr('dangerZone'),
          danger: true,
          children: [
            _tile(Icons.logout, context.tr('logout'), context.tr('logoutHint'), _logout, danger: true),
          ],
        ),
      ],
    );
  }

  Widget _section(BuildContext context, {required String title, required List<Widget> children, bool danger = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: danger ? scheme.errorContainer.withOpacity(0.30) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: danger ? scheme.error : null)),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? Theme.of(context).colorScheme.error : null),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? Theme.of(context).colorScheme.error : null)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return Scaffold(appBar: AppBar(title: Text(context.tr('settings'))), body: SafeArea(child: _content(context)));
  }
}
