import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';
import '../widgets/student_avatar.dart';


Future<void> openAttachment(BuildContext context, Map attachment) async {
  final api = AppScope.of(context).apiClient;
  final raw = attachment['download_url']?.toString() ?? attachment['url']?.toString();
  final url = await api.absoluteUrl(raw);
  if (url == null) return;
  final mime = attachment['mime_type']?.toString() ?? '';
  if (mime.startsWith('image/')) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('connectionProblem')))),
        ),
      ),
    );
    return;
  }
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url)));
  }
}

String _stateLabel(BuildContext context, String? state) {
  switch (state) {
    case 'read':
      return context.tr('readState');
    case 'delivered':
      return context.tr('deliveredState');
    default:
      return context.tr('sentState');
  }
}

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _loadingMore = false;
  String _error = '';
  int _conversationId = 0;
  int _myUserId = 0;
  int _otherId = 0;
  String _title = '';
  String? _avatarUrl;
  String? _stage;
  int? _level;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _conversationId = int.tryParse('${args['conversation_id'] ?? ''}') ?? 0;
      _otherId = int.tryParse('${args['other_id'] ?? ''}') ?? 0;
      _title = '${args['name'] ?? context.tr('privateMessage')}';
      _avatarUrl = args['avatar_url']?.toString();
      _stage = args['stage']?.toString();
      _level = int.tryParse('${args['level'] ?? ''}');
    }
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_conversationId == 0) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final api = AppScope.of(context).apiClient;
    final me = await api.me();
    final res = await api.privateMessages(_conversationId, limit: 20);
    if (!mounted) return;
    setState(() {
      _loading = false;
      final user = me.data?['user'] as Map<String, dynamic>?;
      _myUserId = int.tryParse('${user?['id'] ?? ''}') ?? _myUserId;
      if (res.ok) {
        _messages
          ..clear()
          ..addAll((res.data?['messages'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? 'Could not load messages';
      }
    });
    _scrollBottom();
  }

  Future<void> _loadMore() async {
    if (_messages.isEmpty || _loadingMore) return;
    final before = int.tryParse('${_messages.first['id'] ?? ''}');
    if (before == null) return;
    setState(() => _loadingMore = true);
    final res = await AppScope.of(context).apiClient.privateMessages(_conversationId, before: before, limit: 50);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (res.ok) {
        _messages.insertAll(0, (res.data?['messages'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? 'Could not load more';
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final res = await AppScope.of(context).apiClient.sendPrivateMessage(_conversationId, text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (res.ok) {
        _controller.clear();
        final message = res.data?['message'];
        if (message is Map) _messages.add(Map<String, dynamic>.from(message));
      } else {
        _error = res.error ?? 'Send failed';
      }
    });
    _scrollBottom();
  }

  Future<void> _attach() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _sending = true);
    final res = await AppScope.of(context).apiClient.uploadPrivateAttachment(_conversationId, path);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (res.ok) {
        final message = res.data?['message'];
        if (message is Map) _messages.add(Map<String, dynamic>.from(message));
      } else {
        _error = res.error ?? 'Upload failed';
      }
    });
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _showProfile() {
    final lang = AppScope.of(context).languageCode;
    final stage = _stage ?? '';
    final level = _level ?? 1;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudentAvatar(avatarUrl: _avatarUrl, name: _title, radius: 44),
            const SizedBox(height: 12),
            Text(_title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (stage.isNotEmpty) Text('${stageLabel(stage, lang)} • ${gradeLabel(stage, level, lang)}'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _title.isEmpty ? context.tr('privateMessage') : _title;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _showProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudentAvatar(avatarUrl: _avatarUrl, name: title, radius: 18),
              const SizedBox(width: 8),
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Theme.of(context).colorScheme.errorContainer, child: Text(_error)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(child: Text(context.tr('noMessages')))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) return Center(child: TextButton.icon(onPressed: _loadingMore ? null : _loadMore, icon: const Icon(Icons.history), label: Text(context.tr('loadMore'))));
                            return _PrivateBubble(message: _messages[index - 1], myUserId: _myUserId);
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(onPressed: _sending ? null : _attach, tooltip: context.tr('fileLimit'), icon: const Icon(Icons.attach_file)),
                  Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, decoration: InputDecoration(hintText: context.tr('typeMessage')))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateBubble extends StatelessWidget {
  const _PrivateBubble({required this.message, required this.myUserId});

  final Map<String, dynamic> message;
  final int myUserId;

  @override
  Widget build(BuildContext context) {
    final senderMap = message['sender'] as Map?;
    final sender = senderMap?['name']?.toString() ?? '';
    final senderId = int.tryParse('${senderMap?['user_id'] ?? ''}') ?? 0;
    final isMe = senderId != 0 && senderId == myUserId;
    final text = message['message_text']?.toString() ?? '';
    final attachment = message['attachment'] as Map?;
    final scheme = Theme.of(context).colorScheme;
    final bg = isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isMe ? scheme.onPrimaryContainer : scheme.onSurface;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) Row(children: [StudentAvatar(avatarUrl: senderMap?['avatar_url']?.toString(), name: sender, radius: 12), const SizedBox(width: 6), Flexible(child: Text(sender, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)))]),
              if (!isMe) const SizedBox(height: 5),
              if (text.isNotEmpty) SelectableText(text, style: TextStyle(color: fg, height: 1.45)),
              if (attachment != null) Padding(padding: const EdgeInsets.only(top: 6), child: InkWell(onTap: () => openAttachment(context, attachment), child: Text('📎 ${attachment['original_name'] ?? context.tr('openFile')}', style: TextStyle(color: fg, decoration: TextDecoration.underline)))),
              if (isMe) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_stateLabel(context, message['delivery_state']?.toString()), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg.withOpacity(0.72)))),
            ],
          ),
        ),
      ),
    );
  }
}
