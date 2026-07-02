import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';
import '../widgets/student_avatar.dart';

class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  bool _loading = true;
  String _error = '';
  final List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    final res = await AppScope.of(context).apiClient.privateConversations();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        final list = (res.data?['conversations'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _requests
          ..clear()
          ..addAll(list.where((c) => c['is_message_request'] == 1 || c['is_message_request'] == true));
      } else {
        _error = res.error ?? 'Could not load requests';
      }
    });
  }

  Future<void> _accept(int conversationId) async {
    final res = await AppScope.of(context).apiClient.acceptPrivateMessageRequest(conversationId);
    if (!mounted) return;
    if (res.ok) {
      await _load();
    } else {
      setState(() => _error = res.error ?? 'Failed');
    }
  }

  void _openConversation(Map<String, dynamic> c) {
    final id = int.tryParse('${c['id'] ?? ''}') ?? 0;
    if (id == 0) return;
    Navigator.pushNamed(context, '/private-chat', arguments: {
      'conversation_id': id,
      'other_id': c['other_id'],
      'name': '${c['other_name'] ?? context.tr('privateMessage')}',
      'avatar_url': c['other_avatar_url']?.toString(),
      'stage': c['other_stage']?.toString(),
      'level': c['other_level'],
      'request_status': c['request_status']?.toString(),
      'is_message_request': true,
    }).then((_) => _load());
  }

  void _showProfile(Map<String, dynamic> c) {
    final lang = AppScope.of(context).languageCode;
    final stage = c['other_stage']?.toString() ?? '';
    final level = int.tryParse('${c['other_level'] ?? 1}') ?? 1;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudentAvatar(avatarUrl: c['other_avatar_url']?.toString(), name: '${c['other_name'] ?? ''}', radius: 44),
            const SizedBox(height: 12),
            Text('${c['other_name'] ?? ''}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${stageLabel(stage, lang)} • ${gradeLabel(stage, level, lang)}'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('messageRequests')), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    Text(context.tr('messageRequestInfo')),
                    const SizedBox(height: 12),
                    if (_requests.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('noResults')))),
                    ..._requests.map((c) {
                      final id = int.tryParse('${c['id'] ?? ''}') ?? 0;
                      final name = '${c['other_name'] ?? ''}';
                      final last = '${c['last_message_text'] ?? ''}';
                      return Card(
                        child: ListTile(
                          leading: GestureDetector(onTap: () => _showProfile(c), child: StudentAvatar(avatarUrl: c['other_avatar_url']?.toString(), name: name)),
                          title: GestureDetector(onTap: () => _showProfile(c), child: Text(name)),
                          subtitle: Text(last.isEmpty ? '${c['updated_at'] ?? ''}' : last, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _openConversation(c),
                          trailing: FilledButton(onPressed: () => _accept(id), child: Text(context.tr('accept'))),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
