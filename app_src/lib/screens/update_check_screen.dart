import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';

class UpdateCheckScreen extends StatefulWidget {
  const UpdateCheckScreen({super.key});

  @override
  State<UpdateCheckScreen> createState() => _UpdateCheckScreenState();
}

class _UpdateCheckScreenState extends State<UpdateCheckScreen> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _version;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final res = await AppScope.of(context).apiClient.appVersion();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _version = Map<String, dynamic>.from((res.data?['version'] as Map?) ?? const {});
      } else {
        _error = res.error ?? context.tr('connectionProblem');
      }
    });
  }

  int _intValue(Object? value) => int.tryParse('$value') ?? 0;

  Future<void> _openUpdate() async {
    final version = _version ?? const <String, dynamic>{};
    final url = '${version['apk_url'] ?? version['update_url'] ?? version['play_store_url'] ?? ''}'.trim();
    if (url.isEmpty) {
      setState(() => _error = context.tr('updateUrlMissing'));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) setState(() => _error = context.tr('updateOpenFailed'));
  }

  @override
  Widget build(BuildContext context) {
    final version = _version ?? const <String, dynamic>{};
    final latestBuild = _intValue(version['latest_build'] ?? version['latestBuild']);
    final minBuild = _intValue(version['min_supported_build'] ?? version['minimum_supported_build']);
    final needsUpdate = latestBuild > AppConfig.appBuildNumber;
    final forceUpdate = minBuild > AppConfig.appBuildNumber || version['force_update'] == true;
    final changelog = version['changelog'];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('checkForUpdate'))),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _check,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error.isNotEmpty) AppErrorBox(message: _error),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              if (!_loading)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(needsUpdate ? Icons.system_update_alt : Icons.verified, size: 44, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(needsUpdate ? context.tr('updateAvailable') : context.tr('latestVersionInstalled'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        _row(context.tr('currentVersion'), '${AppConfig.appVersionName}+${AppConfig.appBuildNumber}'),
                        _row(context.tr('latestVersion'), '${version['latest_version'] ?? '-'}+${latestBuild == 0 ? '-' : latestBuild}'),
                        if (forceUpdate) Padding(padding: const EdgeInsets.only(top: 8), child: Text(context.tr('forceUpdateRequired'), style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
                        if (changelog != null) ...[
                          const SizedBox(height: 12),
                          Text(context.tr('changelog'), style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(changelog is List ? changelog.map((e) => '• $e').join('\n') : '$changelog'),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(onPressed: needsUpdate || forceUpdate ? _openUpdate : _check, icon: Icon(needsUpdate || forceUpdate ? Icons.download : Icons.refresh), label: Text(needsUpdate || forceUpdate ? context.tr('updateNow') : context.tr('refresh'))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );
}
