import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final List<Map<String, dynamic>> _requests = [];
  final List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  Future<void> _respond(int id, String action) async {
    final res = await AppScope.of(context).apiClient.respondFriendRequest(id, action);
    if (!mounted) return;
    if (!res.ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed')));
    await _load();
  }

  Future<void> _openChat(int otherId, String name) async {
    final res = await AppScope.of(context).apiClient.createPrivateConversation(otherId);
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? context.tr('onlyFriendsCanChat'))));
      return;
    }
    final conv = res.data?['conversation'] as Map?;
    final id = int.tryParse('${conv?['id'] ?? ''}') ?? 0;
    if (id == 0) return;
    Navigator.pushNamed(context, '/private-chat', arguments: {'conversation_id': id, 'name': name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('friends')), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  Text(context.tr('incomingRequests'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_requests.isEmpty) Text(context.tr('noResults')),
                  ..._requests.map((r) {
                    final id = int.tryParse('${r['id'] ?? ''}') ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text('${r['requester_name'] ?? ''}'),
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
                  const SizedBox(height: 24),
                  Text(context.tr('myFriends'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_friends.isEmpty) Text(context.tr('noResults')),
                  ..._friends.map((f) {
                    final id = int.tryParse('${f['user_id'] ?? ''}') ?? 0;
                    final name = '${f['name'] ?? ''}';
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text('${f['grade_label_ar'] ?? f['grade_label_en'] ?? ''}'),
                        trailing: IconButton(onPressed: () => _openChat(id, name), icon: const Icon(Icons.message)),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
