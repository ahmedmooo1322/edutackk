import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/student_avatar.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _room;
  final List<Map<String, dynamic>> _inbox = [];
  final List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    final api = AppScope.of(context).apiClient;
    final roomRes = await api.myLevelRoom();
    final convRes = await api.privateConversations();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (roomRes.ok) _room = Map<String, dynamic>.from(roomRes.data?['room'] as Map? ?? const {});
      if (convRes.ok) {
        final list = (convRes.data?['conversations'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _inbox
          ..clear()
          ..addAll(list.where((c) => c['is_message_request'] != 1 && c['is_message_request'] != true));
        _requests
          ..clear()
          ..addAll(list.where((c) => c['is_message_request'] == 1 || c['is_message_request'] == true));
      } else {
        _error = convRes.error ?? 'Could not load inbox';
      }
      if (!roomRes.ok && _error.isEmpty) _error = roomRes.error ?? '';
    });
  }

  Future<void> _accept(int conversationId) async {
    final res = await AppScope.of(context).apiClient.acceptPrivateMessageRequest(conversationId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('accepted') : (res.error ?? 'Failed'))));
    if (res.ok) await _load();
  }

  void _openConversation(Map<String, dynamic> c) {
    final id = int.tryParse('${c['id'] ?? ''}') ?? 0;
    if (id == 0) return;
    Navigator.pushNamed(context, '/private-chat', arguments: {
      'conversation_id': id,
      'name': '${c['other_name'] ?? context.tr('privateMessage')}',
      'request_status': c['request_status']?.toString(),
      'is_message_request': c['is_message_request'] == 1 || c['is_message_request'] == true,
    }).then((_) => _load());
  }

  Widget _conversationTile(Map<String, dynamic> c, {bool request = false}) {
    final id = int.tryParse('${c['id'] ?? ''}') ?? 0;
    final name = '${c['other_name'] ?? ''}';
    final last = '${c['last_message_text'] ?? ''}';
    return Card(
      child: ListTile(
        leading: StudentAvatar(avatarUrl: c['other_avatar_url']?.toString(), name: name),
        title: Text(name),
        subtitle: Text(last.isEmpty ? '${c['updated_at'] ?? ''}' : last, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => _openConversation(c),
        trailing: request ? FilledButton(onPressed: () => _accept(id), child: Text(context.tr('accept'))) : const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: [
          if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Text(context.tr('levelRoomPinned'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.groups_2)),
              title: Text(_room == null ? context.tr('levelRoom') : '${_room?[lang == 'ar' ? 'title_ar' : 'title_en'] ?? context.tr('levelRoom')}'),
              subtitle: Text(context.tr('levelRoomSubtitle')),
              trailing: const Icon(Icons.push_pin),
              onTap: () => Navigator.pushNamed(context, '/level-room'),
            ),
          ),
          const SizedBox(height: 22),
          Text(context.tr('inbox'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_inbox.isEmpty) Text(context.tr('noMessages')),
          ..._inbox.map((c) => _conversationTile(c)),
          const SizedBox(height: 22),
          Text(context.tr('messageRequests'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(context.tr('messageRequestInfo')),
          const SizedBox(height: 8),
          if (_requests.isEmpty) Text(context.tr('noResults')),
          ..._requests.map((c) => _conversationTile(c, request: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return Scaffold(appBar: AppBar(title: Text(context.tr('inbox')), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]), body: SafeArea(child: _content(context)));
  }
}
