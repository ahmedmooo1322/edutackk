import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _loading = true;
  String _error = '';
  final List<Map<String, dynamic>> _blocks = [];

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
    final res = await AppScope.of(context).apiClient.blockedUsers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _blocks.clear();
      if (res.ok) {
        _blocks.addAll((res.data?['blocks'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? context.tr('connectionProblem');
      }
    });
  }

  Future<void> _unblock(Map<String, dynamic> block) async {
    final id = int.tryParse('${block['blocked_id']}') ?? 0;
    if (id <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('unblock')),
        content: Text(context.tr('unblockConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('unblock'))),
        ],
      ),
    );
    if (ok != true) return;
    final res = await AppScope.of(context).apiClient.unblockUser(id);
    if (!mounted) return;
    if (res.ok) {
      await _load();
    } else {
      setState(() => _error = res.error ?? context.tr('connectionProblem'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('blockedUsers'))),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error.isNotEmpty) AppErrorBox(message: _error),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              if (!_loading && _blocks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(Icons.block, size: 44),
                        const SizedBox(height: 10),
                        Text(context.tr('noBlockedUsers'), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ..._blocks.map((block) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${block['blocked_name'] ?? '?'}'.trim().isEmpty ? '?' : '${block['blocked_name']}'.trim()[0].toUpperCase())),
                      title: Text('${block['blocked_name'] ?? ''}'.trim().isEmpty ? context.tr('student') : '${block['blocked_name']}'),
                      subtitle: Text(block['reason'] == null || '${block['reason']}'.isEmpty ? context.tr('blockedUser') : '${block['reason']}'),
                      trailing: TextButton(onPressed: () => _unblock(block), child: Text(context.tr('unblock'))),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
