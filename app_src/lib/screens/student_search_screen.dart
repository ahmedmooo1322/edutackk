import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/student_avatar.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final _query = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _message = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    final res = await AppScope.of(context).apiClient.searchStudents(_query.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _results
          ..clear()
          ..addAll((res.data?['students'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        if (_results.isEmpty) _message = context.tr('noResults');
      } else {
        _message = res.error ?? 'Search failed';
      }
    });
  }

  Future<void> _openChat(int otherId, String name) async {
    final res = await AppScope.of(context).apiClient.createPrivateConversation(otherId);
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed')));
      return;
    }
    final conv = res.data?['conversation'] as Map?;
    final id = int.tryParse('${conv?['id'] ?? ''}') ?? 0;
    if (id == 0) return;
    Navigator.pushNamed(context, '/private-chat', arguments: {
      'conversation_id': id,
      'other_id': otherId,
      'name': name,
      'avatar_url': conv?['other_avatar_url'],
      'stage': conv?['other_stage'],
      'level': conv?['other_level'],
    });
  }

  Future<void> _friend(int id) async {
    final res = await AppScope.of(context).apiClient.sendFriendRequest(id);
    if (!mounted) return;
    final already = res.data?['already_pending'] == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? (already ? context.tr('requestAlreadySent') : context.tr('friendRequestSent')) : (res.error ?? 'Failed'))));
  }

  Future<void> _block(int id) async {
    final res = await AppScope.of(context).apiClient.blockUser(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('block') : (res.error ?? 'Failed'))));
  }


  Future<void> _unfriend(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('unfriend')),
        content: Text(context.tr('unfriendConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('unfriend'))),
        ],
      ),
    );
    if (ok != true) return;
    final res = await AppScope.of(context).apiClient.unfriend(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('saved') : (res.error ?? 'Failed'))));
    if (res.ok) _search();
  }

  Future<void> _report(int id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(context.tr('report')),
          content: TextField(controller: c, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Reason')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(context.tr('send'))),
          ],
        );
      },
    );
    if (reason == null || reason.trim().length < 3) return;
    final res = await AppScope.of(context).apiClient.reportUser(id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('report') : (res.error ?? 'Failed'))));
  }


  void _openPublicProfile(Map<String, dynamic> s) {
    final lang = AppScope.of(context).languageCode;
    final id = int.tryParse('${s['user_id'] ?? ''}') ?? 0;
    final name = '${s['name'] ?? ''}';
    final grade = s[lang == 'ar' ? 'grade_label_ar' : 'grade_label_en']?.toString() ?? '';
    final stage = s[lang == 'ar' ? 'stage_label_ar' : 'stage_label_en']?.toString() ?? '';
    final status = s['relationship_status']?.toString() ?? 'none';
    final alreadyFriend = status == 'friends';
    final requestSent = status == 'request_sent';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudentAvatar(avatarUrl: s['avatar_url']?.toString(), name: name, radius: 42),
              const SizedBox(height: 10),
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              Text('$stage • $grade'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(onPressed: () { Navigator.pop(context); _openChat(id, name); }, icon: const Icon(Icons.message), label: Text(context.tr('message'))),
                  if (alreadyFriend)
                    FilledButton.tonalIcon(onPressed: () { Navigator.pop(context); _unfriend(id); }, icon: const Icon(Icons.person_remove), label: Text(context.tr('unfriend')))
                  else if (requestSent)
                    FilledButton.tonal(onPressed: null, child: Text(context.tr('requestAlreadySent')))
                  else
                    FilledButton.tonalIcon(onPressed: () { Navigator.pop(context); _friend(id); }, icon: const Icon(Icons.person_add_alt_1), label: Text(context.tr('sendFriendRequest'))),
                  FilledButton.tonalIcon(onPressed: () { Navigator.pop(context); _report(id); }, icon: const Icon(Icons.flag), label: Text(context.tr('report'))),
                  FilledButton.tonalIcon(onPressed: () { Navigator.pop(context); _block(id); }, icon: const Icon(Icons.block), label: Text(context.tr('block'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('searchStudents'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _query, decoration: InputDecoration(labelText: context.tr('searchStudents')))),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _loading ? null : _search, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search)),
              ],
            ),
            if (_message.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(_message)),
            ..._results.map((s) {
              final id = int.tryParse('${s['user_id'] ?? ''}') ?? 0;
              final grade = s[lang == 'ar' ? 'grade_label_ar' : 'grade_label_en']?.toString() ?? '';
              final stage = s[lang == 'ar' ? 'stage_label_ar' : 'stage_label_en']?.toString() ?? '';
              final relation = s['relationship_status']?.toString() ?? 'none';
              return Card(
                child: ListTile(
                  leading: StudentAvatar(avatarUrl: s['avatar_url']?.toString(), name: '${s['name'] ?? ''}'),
                  title: Text('${s['name'] ?? ''}'),
                  subtitle: Text('$stage • $grade'),
                  onTap: () => _openPublicProfile(s),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'friend') _friend(id);
                      if (value == 'report') _report(id);
                      if (value == 'block') _block(id);
                      if (value == 'unfriend') _unfriend(id);
                    },
                    itemBuilder: (context) => [
                      if (relation == 'friends')
                        PopupMenuItem(value: 'unfriend', child: Text(context.tr('unfriend')))
                      else if (relation == 'request_sent')
                        PopupMenuItem(enabled: false, child: Text(context.tr('requestAlreadySent')))
                      else
                        PopupMenuItem(value: 'friend', child: Text(context.tr('sendFriendRequest'))),
                      PopupMenuItem(value: 'report', child: Text(context.tr('report'))),
                      PopupMenuItem(value: 'block', child: Text(context.tr('block'))),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
