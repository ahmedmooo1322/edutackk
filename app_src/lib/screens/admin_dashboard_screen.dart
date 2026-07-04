import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../services/api_client.dart';
import '../widgets/app_error_box.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late ApiClient _api;
  bool _started = false;
  final _search = TextEditingController();
  bool _loadingUsers = false;
  String _error = '';
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _reports = const [];
  List<Map<String, dynamic>> _deletionRequests = const [];
  List<Map<String, dynamic>> _auditLogs = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).apiClient;
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshAll();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _listFrom(dynamic value) {
    return (value as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadUsers(), _loadReports(), _loadDeletionRequests(), _loadAuditLogs()]);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _error = '';
    });
    final result = await _api.adminUsers(q: _search.text);
    if (!mounted) return;
    setState(() {
      _loadingUsers = false;
      if (result.ok) {
        _users = _listFrom(result.data?['users']);
      } else {
        _error = result.error ?? context.tr('connectionProblem');
      }
    });
  }

  Future<void> _loadReports() async {
    final result = await _api.adminReports();
    if (!mounted) return;
    if (result.ok) setState(() => _reports = _listFrom(result.data?['reports']));
  }

  Future<void> _loadDeletionRequests() async {
    final result = await _api.adminAccountDeletionRequests();
    if (!mounted) return;
    if (result.ok) setState(() => _deletionRequests = _listFrom(result.data?['requests']));
  }

  Future<void> _loadAuditLogs() async {
    final result = await _api.adminAuditLogs();
    if (!mounted) return;
    if (result.ok) setState(() => _auditLogs = _listFrom(result.data?['logs']));
  }

  Future<String?> _askReason(String title) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: context.tr('adminReason')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(context.tr('ok'))),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().length < 3) return null;
    return value.trim();
  }

  Future<void> _setStatus(Map<String, dynamic> user, String status) async {
    final id = int.tryParse('${user['id']}');
    if (id == null) return;
    final reason = await _askReason('${context.tr('adminChangeStatus')} → $status');
    if (reason == null) return;
    final result = await _api.adminSetUserStatus(id, status, reason: reason);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? context.tr('connectionProblem'))));
      return;
    }
    await _loadUsers();
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final id = int.tryParse('${user['id']}');
    if (id == null) return;
    final name = TextEditingController(text: '${user['name'] ?? ''}');
    final email = TextEditingController(text: '${user['email'] ?? ''}');
    final phone = TextEditingController(text: '${user['phone'] ?? ''}');
    final username = TextEditingController(text: '${user['username'] ?? ''}');
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('editUser')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: context.tr('name'))),
              const SizedBox(height: 8),
              TextField(controller: email, decoration: InputDecoration(labelText: context.tr('email'))),
              const SizedBox(height: 8),
              TextField(controller: phone, decoration: InputDecoration(labelText: context.tr('phone'))),
              const SizedBox(height: 8),
              TextField(controller: username, decoration: InputDecoration(labelText: context.tr('username'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'name': name.text.trim(),
              'email': email.text.trim().isEmpty ? null : email.text.trim(),
              'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
              'username': username.text.trim().isEmpty ? null : username.text.trim().toLowerCase(),
            }),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    phone.dispose();
    username.dispose();
    if (body == null) return;
    final result = await _api.adminUpdateUser(id, body);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? context.tr('connectionProblem'))));
      return;
    }
    await _loadUsers();
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final id = int.tryParse('${user['id']}');
    if (id == null) return;
    final password = TextEditingController();
    final confirm = TextEditingController();
    final reason = TextEditingController();
    bool forceLogout = true;
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: Text(context.tr('resetPassword')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: context.tr('newPassword'))),
                const SizedBox(height: 8),
                TextField(controller: confirm, obscureText: true, decoration: InputDecoration(labelText: context.tr('confirmPassword'))),
                const SizedBox(height: 8),
                TextField(controller: reason, minLines: 2, maxLines: 3, decoration: InputDecoration(labelText: context.tr('adminReason'))),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('forceLogoutUser')),
                  value: forceLogout,
                  onChanged: (v) => setLocalState(() => forceLogout = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () {
                final p = password.text.trim();
                if (p.length < 8 || p != confirm.text.trim() || reason.text.trim().length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('passwordResetValidation'))));
                  return;
                }
                Navigator.pop(dialogContext, {'password': p, 'reason': reason.text.trim(), 'force_logout': forceLogout});
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    confirm.dispose();
    reason.dispose();
    if (body == null) return;
    final result = await _api.adminResetUserPassword(id, body['password'] as String, body['reason'] as String, forceLogout: body['force_logout'] == true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.ok ? context.tr('passwordResetDone') : (result.error ?? context.tr('connectionProblem')))));
    if (result.ok) await _loadAuditLogs();
  }

  Future<void> _openInbox(Map<String, dynamic> user) async {
    final id = int.tryParse('${user['id']}');
    if (id == null) return;
    final reason = await _askReason(context.tr('adminViewInbox'));
    if (reason == null) return;
    final result = await _api.adminUserChats(id, reason);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? context.tr('connectionProblem'))));
      return;
    }
    final chatsData = result.data?['chats'];
    final conversations = _listFrom(chatsData is Map ? chatsData['conversations'] : null);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(context.tr('adminUserInbox'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (conversations.isEmpty) Text(context.tr('noMessages')),
              for (final c in conversations)
                Card(
                  child: ListTile(
                    title: Text('${c['other_name'] ?? c['other_username'] ?? c['other_id']}'),
                    subtitle: Text('${c['last_message_text'] ?? ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openConversationMessages(int.tryParse('${c['id']}') ?? 0, reason),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openConversationMessages(int conversationId, String reason) async {
    if (conversationId <= 0) return;
    final result = await _api.adminPrivateMessages(conversationId, reason);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? context.tr('connectionProblem'))));
      return;
    }
    final messages = _listFrom(result.data?['messages']);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('privateMessage')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in messages)
                ListTile(
                  title: Text('${(m['sender'] as Map?)?['name'] ?? ''}'),
                  subtitle: Text('${m['message_text'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deletePrivateMessage(int.tryParse('${m['id']}') ?? 0),
                  ),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('ok')))],
      ),
    );
  }

  Future<void> _deletePrivateMessage(int messageId) async {
    if (messageId <= 0) return;
    final reason = await _askReason(context.tr('adminDeleteMessage'));
    if (reason == null) return;
    final result = await _api.adminDeletePrivateMessage(messageId, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.ok ? context.tr('saved') : (result.error ?? context.tr('connectionProblem')))));
  }

  Future<void> _reviewDeletion(Map<String, dynamic> request, String action) async {
    final id = int.tryParse('${request['id']}');
    if (id == null) return;
    final reason = await _askReason(action == 'approve' ? context.tr('adminApproveDeletion') : context.tr('adminRejectDeletion'));
    if (reason == null) return;
    final result = await _api.adminReviewAccountDeletion(id, action, notes: reason);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? context.tr('connectionProblem'))));
      return;
    }
    await _loadDeletionRequests();
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Widget _usersTab() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppErrorBox(message: _error),
          Row(
            children: [
              Expanded(child: TextField(controller: _search, decoration: InputDecoration(labelText: context.tr('search')))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _loadUsers, icon: const Icon(Icons.search)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingUsers) const LinearProgressIndicator(),
          for (final user in _users)
            Card(
              child: ExpansionTile(
                title: Text('${user['name'] ?? ''}'),
                subtitle: Text('${user['role'] ?? ''} • ${user['status'] ?? ''} • @${user['username'] ?? ''}'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(onPressed: () => _editUser(user), child: Text(context.tr('editUser'))),
                      FilledButton.tonal(onPressed: () => _setStatus(user, 'active'), child: Text(context.tr('activate'))),
                      FilledButton.tonal(onPressed: () => _setStatus(user, 'suspended'), child: Text(context.tr('suspend'))),
                      FilledButton.tonal(onPressed: () => _setStatus(user, 'deleted'), child: Text(context.tr('ban'))),
                      FilledButton.tonalIcon(onPressed: () => _resetPassword(user), icon: const Icon(Icons.password), label: Text(context.tr('resetPassword'))),
                      OutlinedButton.icon(onPressed: () => _openInbox(user), icon: const Icon(Icons.inbox_outlined), label: Text(context.tr('adminViewInbox'))),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _reportsTab() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_reports.isEmpty) Text(context.tr('noResults')),
          for (final report in _reports)
            Card(
              child: ListTile(
                title: Text('${report['reason'] ?? ''}'),
                subtitle: Text('${report['reporter_name'] ?? ''} → ${report['reported_name'] ?? ''}\n${report['status'] ?? ''}'),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _deletionTab() {
    return RefreshIndicator(
      onRefresh: _loadDeletionRequests,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_deletionRequests.isEmpty) Text(context.tr('noResults')),
          for (final r in _deletionRequests)
            Card(
              child: ListTile(
                title: Text('${r['name'] ?? ''}'),
                subtitle: Text('${r['email'] ?? r['phone'] ?? r['username'] ?? ''}\n${r['reason'] ?? ''}'),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(onPressed: () => _reviewDeletion(r, 'reject'), icon: const Icon(Icons.close)),
                    IconButton(onPressed: () => _reviewDeletion(r, 'approve'), icon: const Icon(Icons.check)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _auditTab() {
    return RefreshIndicator(
      onRefresh: _loadAuditLogs,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_auditLogs.isEmpty) Text(context.tr('noResults')),
          for (final log in _auditLogs)
            Card(
              child: ListTile(
                title: Text('${log['action'] ?? ''}'),
                subtitle: Text('${log['admin_name'] ?? 'API key'} • ${log['target_type'] ?? ''} #${log['target_id'] ?? ''}\n${log['created_at'] ?? ''}'),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _overviewTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricCard(icon: Icons.people_alt_outlined, title: context.tr('users'), value: '${_users.length}'),
          _MetricCard(icon: Icons.report_outlined, title: context.tr('reports'), value: '${_reports.length}'),
          _MetricCard(icon: Icons.delete_outline, title: context.tr('accountDeletionRequests'), value: '${_deletionRequests.length}'),
          _MetricCard(icon: Icons.history, title: context.tr('adminAuditLogs'), value: '${_auditLogs.length}'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _refreshAll, icon: const Icon(Icons.refresh), label: Text(context.tr('refresh'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('adminMode')),
          actions: [
            IconButton(
              tooltip: context.tr('switchToNormalMode'),
              onPressed: () async {
                await AppScope.of(context).sessionStore.setAdminPreferredMode('normal');
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
              },
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.tr('overview')),
              Tab(text: context.tr('users')),
              Tab(text: context.tr('reports')),
              Tab(text: context.tr('accountDeletionRequests')),
              Tab(text: context.tr('adminAuditLogs')),
            ],
          ),
        ),
        body: TabBarView(
          children: [_overviewTab(), _usersTab(), _reportsTab(), _deletionTab(), _auditTab()],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
