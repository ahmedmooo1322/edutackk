import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

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

  Future<void> _friend(int id) async {
    final res = await AppScope.of(context).apiClient.sendFriendRequest(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('friendRequestSent') : (res.error ?? 'Failed'))));
  }

  Future<void> _block(int id) async {
    final res = await AppScope.of(context).apiClient.blockUser(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('block') : (res.error ?? 'Failed'))));
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
              return Card(
                child: ListTile(
                  title: Text('${s['name'] ?? ''}'),
                  subtitle: Text('$stage • $grade'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'friend') _friend(id);
                      if (value == 'report') _report(id);
                      if (value == 'block') _block(id);
                    },
                    itemBuilder: (context) => [
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
