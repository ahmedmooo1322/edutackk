import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';
import '../widgets/app_error_box.dart';
import '../widgets/student_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _uploading = false;
  String _error = '';
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _student;
  Map<String, dynamic>? _subscription;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(AppScope.of(context));
  }

  Future<void> _load([AppScope? scope]) async {
    final app = scope ?? AppScope.of(context);
    setState(() {
      _loading = true;
      _error = '';
    });
    final me = await app.apiClient.me();
    final profile = await app.apiClient.studentProfile();
    final sub = await app.apiClient.subscription();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (me.ok) _user = me.data?['user'] as Map<String, dynamic>?;
      if (profile.ok) _student = profile.data?['student'] as Map<String, dynamic>?;
      if (sub.ok) _subscription = sub.data;
      _error = [if (!me.ok) me.error, if (!profile.ok) profile.error, if (!sub.ok) sub.error].whereType<String>().join('\n');
    });
  }

  Future<void> _uploadPhoto() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() {
      _uploading = true;
      _error = '';
    });
    final res = await AppScope.of(context).apiClient.uploadProfilePhoto(path);
    if (!mounted) return;
    if (res.ok) {
      setState(() {
        _uploading = false;
        _error = context.tr('profilePhotoUpdated');
      });
      await _load();
    } else {
      setState(() {
        _uploading = false;
        _error = res.error ?? 'Upload failed';
      });
    }
  }

  Widget _content(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    final user = _user ?? const <String, dynamic>{};
    final student = _student ?? (user['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final stage = student['stage']?.toString() ?? '';
    final level = int.tryParse('${student['level'] ?? 1}') ?? 1;
    final plan = (_subscription?['plan'] as Map<String, dynamic>?) ?? (student['plan'] as Map<String, dynamic>? ?? const {});
    final usage = (_subscription?['usage'] as Map<String, dynamic>?) ?? (student['usage'] as Map<String, dynamic>? ?? const {});
    final avatar = user['avatar_url']?.toString() ?? student['avatar_url']?.toString();
    final name = '${user['name'] ?? student['name'] ?? context.tr('student')}';

    if (_loading) return Center(child: Text(context.tr('loadingAccount')));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: [
          AppErrorBox(message: _error),
          if (_error.isNotEmpty)
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(context.tr('retry'))),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      StudentAvatar(avatarUrl: avatar, name: name, radius: 48),
                      CircleAvatar(
                        radius: 18,
                        child: _uploading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(padding: EdgeInsets.zero, iconSize: 18, onPressed: _uploadPhoto, icon: const Icon(Icons.camera_alt)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  if ((user['username'] ?? '').toString().isNotEmpty) Text('@${user['username']}'),
                  const SizedBox(height: 8),
                  if ((user['role'] ?? 'student') == 'student') Text('${stageLabel(stage, lang)} • ${gradeLabel(stage, level, lang)}', textAlign: TextAlign.center) else Text(context.tr('teacher'), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if ((user['role'] ?? 'student') == 'student') Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('subscription'), style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  _InfoTile(label: context.tr('status'), value: plan['active'] == true ? context.tr('subscriptionActive') : context.tr('subscriptionNotActive')),
                  _InfoTile(label: context.tr('dailyLimit'), value: '${plan['daily_ai_limit'] ?? usage['daily_limit'] ?? '-'}'),
                  _InfoTile(label: context.tr('remainingToday'), value: '${usage['remaining_today'] ?? '-'} ${context.tr('messages')}'),
                  _InfoTile(label: context.tr('expiresAt'), value: '${_subscription?['subscription_expires_at'] ?? student['subscription_expires_at'] ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoTile(label: context.tr('studentId'), value: '${user['id'] ?? student['user_id'] ?? '-'}'),
          _InfoTile(label: context.tr('publicId'), value: '${user['public_id'] ?? student['public_id'] ?? '-'}'),
          _InfoTile(label: context.tr('email'), value: '${user['email'] ?? student['email'] ?? '-'}'),
          _InfoTile(label: context.tr('phone'), value: '${user['phone'] ?? student['phone'] ?? '-'}'),
          _InfoTile(label: context.tr('username'), value: '${user['username'] ?? student['username'] ?? '-'}'),
          _InfoTile(label: context.tr('accountStatus'), value: '${user['status'] ?? student['status'] ?? '-'}'),
          _InfoTile(label: context.tr('preferredLanguage'), value: '${user['preferred_language'] ?? '-'}'),
          _InfoTile(label: context.tr('overallRate'), value: '${student['overall_rate'] ?? 0}'),
          _InfoTile(label: context.tr('questionsAsked'), value: '${student['total_questions_asked'] ?? 0}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return Scaffold(appBar: AppBar(title: Text(context.tr('profile'))), body: SafeArea(child: _content(context)));
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(label),
        subtitle: SelectableText(value),
      ),
    );
  }
}
