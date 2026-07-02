import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/student_avatar.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final _query = TextEditingController();
  final List<Map<String, dynamic>> _requests = [];
  final List<Map<String, dynamic>> _friends = [];
  final List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  bool _searching = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final api = AppScope.of(context).apiClient;
    final reqRes = await api.friendRequests();
    final friendRes = await api.friends();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (reqRes.ok) {
        _requests
          ..clear()
          ..addAll((reqRes.data?['requests'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = reqRes.error ?? 'Could not load requests';
      }
      if (friendRes.ok) {
        _friends
          ..clear()
          ..addAll((friendRes.data?['friends'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = friendRes.error ?? _error;
      }
    });
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) {
      setState(() => _results.clear());
      return;
    }
    setState(() => _searching = true);
    final res = await AppScope.of(context).apiClient.searchStudents(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (res.ok) {
        _results
          ..clear()
          ..addAll((res.data?['students'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? 'Search failed';
      }
    });
  }

  Future<void> _respond(int id, String action) async {
    final res = await AppScope.of(context).apiClient.respondFriendRequest(id, action);
    if (!mounted) return;
    if (!res.ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed')));
    await _load();
  }

  Future<void> _friend(int id) async {
    final res = await AppScope.of(context).apiClient.sendFriendRequest(id);
    if (!mounted) return;
    final already = res.data?['already_pending'] == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? (already ? context.tr('requestAlreadySent') : context.tr('friendRequestSent')) : (res.error ?? 'Failed'))));
  }

  Future<void> _openChat(int otherId, String name) async {
    final res = await AppScope.of(context).apiClient.createPrivateConversation(otherId);
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? context.tr('messageRequestInfo'))));
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
      'request_status': conv?['request_status'],
    });
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
          content: TextField(controller: c, minLines: 2, maxLines: 4, decoration: InputDecoration(hintText: context.tr('reportReason'))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(context.tr('send'))),
          ],
        );
      },
    );
    if (reason == null || reason.trim().length < 3) return;
    final res = await AppScope.of(context).apiClient.reportUser(id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('reportSent') : (res.error ?? 'Failed'))));
  }

  void _openPublicProfile(Map<String, dynamic> s) {
    final lang = AppScope.of(context).languageCode;
    final id = int.tryParse('${s['user_id'] ?? ''}') ?? 0;
    final name = '${s['name'] ?? ''}';
    final grade = s[lang == 'ar' ? 'grade_label_ar' : 'grade_label_en']?.toString() ?? '';
    final stage = s[lang == 'ar' ? 'stage_label_ar' : 'stage_label_en']?.toString() ?? '';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.icon(onPressed: () { Navigator.pop(context); _openChat(id, name); }, icon: const Icon(Icons.message), label: Text(context.tr('message'))),
                  IconButton.filledTonal(onPressed: () => _friend(id), icon: const Icon(Icons.person_add_alt_1)),
                  PopupMenuButton<String>(
                    onSelected: (value) { if (value == 'report') _report(id); if (value == 'block') _block(id); },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'report', child: Text(context.tr('report'))),
                      PopupMenuItem(value: 'block', child: Text(context.tr('block'))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    final searchingMode = _query.text.trim().isNotEmpty;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: [
          TextField(
            controller: _query,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: context.tr('searchStudents')),
            onChanged: (_) { setState(() {}); _search(); },
          ),
          const SizedBox(height: 12),
          if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (searchingMode) ...[
            if (_searching) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            if (!_searching && _results.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(context.tr('noResults'))),
            ..._results.map((s) {
              final name = '${s['name'] ?? ''}';
              final grade = s[lang == 'ar' ? 'grade_label_ar' : 'grade_label_en']?.toString() ?? '';
              final stage = s[lang == 'ar' ? 'stage_label_ar' : 'stage_label_en']?.toString() ?? '';
              return Card(
                child: ListTile(
                  leading: StudentAvatar(avatarUrl: s['avatar_url']?.toString(), name: name),
                  title: Text(name),
                  subtitle: Text('$stage • $grade'),
                  onTap: () => _openPublicProfile(s),
                ),
              );
            }),
          ] else ...[
            Text(context.tr('myFriends'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_friends.isEmpty) Text(context.tr('noResults')),
            ..._friends.map((f) {
              final id = int.tryParse('${f['user_id'] ?? ''}') ?? 0;
              final name = '${f['name'] ?? ''}';
              final grade = f[lang == 'ar' ? 'grade_label_ar' : 'grade_label_en']?.toString() ?? '';
              return Card(
                child: ListTile(
                  leading: StudentAvatar(avatarUrl: f['avatar_url']?.toString(), name: name),
                  title: Text(name),
                  subtitle: Text(grade),
                  trailing: IconButton(onPressed: () => _openChat(id, name), icon: const Icon(Icons.message)),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(context.tr('incomingRequests'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_requests.isEmpty) Text(context.tr('noResults')),
            ..._requests.map((r) {
              final id = int.tryParse('${r['id'] ?? ''}') ?? 0;
              final name = '${r['requester_name'] ?? ''}';
              return Card(
                child: ListTile(
                  leading: StudentAvatar(avatarUrl: r['requester_avatar_url']?.toString(), name: name),
                  title: Text(name),
                  subtitle: Text('${r['created_at'] ?? ''}'),
                  trailing: Wrap(
                    children: [
                      IconButton(onPressed: () => _respond(id, 'accept'), icon: const Icon(Icons.check)),
                      IconButton(onPressed: () => _respond(id, 'reject'), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return Scaffold(appBar: AppBar(title: Text(context.tr('friends')), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]), body: SafeArea(child: _content(context)));
  }
}
