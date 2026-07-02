import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/student_avatar.dart';

class LevelRoomScreen extends StatefulWidget {
  const LevelRoomScreen({super.key});

  @override
  State<LevelRoomScreen> createState() => _LevelRoomScreenState();
}

class _LevelRoomScreenState extends State<LevelRoomScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Map<String, dynamic>? _room;
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _loadingMore = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final api = AppScope.of(context).apiClient;
    final roomRes = await api.myLevelRoom();
    if (!mounted) return;
    if (!roomRes.ok) {
      setState(() {
        _loading = false;
        _error = roomRes.error ?? 'Could not load room';
      });
      return;
    }
    _room = Map<String, dynamic>.from(roomRes.data?['room'] as Map? ?? const {});
    final roomId = int.tryParse('${_room?['id'] ?? ''}') ?? 0;
    final msgRes = await api.roomMessages(roomId, limit: 20);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (msgRes.ok) {
        _messages
          ..clear()
          ..addAll((msgRes.data?['messages'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = msgRes.error ?? 'Could not load messages';
      }
    });
    _scrollBottom();
  }

  Future<void> _loadMore() async {
    if (_room == null || _messages.isEmpty || _loadingMore) return;
    final before = int.tryParse('${_messages.first['id'] ?? ''}');
    final roomId = int.tryParse('${_room?['id'] ?? ''}') ?? 0;
    if (before == null) return;
    setState(() => _loadingMore = true);
    final res = await AppScope.of(context).apiClient.roomMessages(roomId, before: before, limit: 50);
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
    final roomId = int.tryParse('${_room?['id'] ?? ''}') ?? 0;
    if (text.isEmpty || roomId == 0 || _sending) return;
    setState(() => _sending = true);
    final res = await AppScope.of(context).apiClient.sendRoomMessage(roomId, text);
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
    final roomId = int.tryParse('${_room?['id'] ?? ''}') ?? 0;
    if (roomId == 0 || _sending) return;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _sending = true);
    final res = await AppScope.of(context).apiClient.uploadRoomAttachment(roomId, path);
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

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    final title = _room == null ? context.tr('levelRoom') : '${_room?[lang == 'ar' ? 'title_ar' : 'title_en'] ?? context.tr('levelRoom')}';
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: SafeArea(
        child: Column(
          children: [
            if (_error.isNotEmpty)
              Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Theme.of(context).colorScheme.errorContainer, child: Text(_error)),
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
                            if (index == 0) {
                              return Center(child: TextButton.icon(onPressed: _loadingMore ? null : _loadMore, icon: const Icon(Icons.history), label: Text(context.tr('loadMore'))));
                            }
                            return _CommunityBubble(message: _messages[index - 1]);
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

class _CommunityBubble extends StatelessWidget {
  const _CommunityBubble({required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final sender = (message['sender'] as Map?)?['name']?.toString() ?? '';
    final text = message['message_text']?.toString() ?? '';
    final attachment = message['attachment'] as Map?;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [StudentAvatar(avatarUrl: (message['sender'] as Map?)?['avatar_url']?.toString(), name: sender, radius: 14), const SizedBox(width: 8), Text(sender, style: Theme.of(context).textTheme.labelLarge)]),
            const SizedBox(height: 6),
            if (text.isNotEmpty) SelectableText(text),
            if (attachment != null) Text('📎 ${attachment['original_name'] ?? 'file'}'),
          ],
        ),
      ),
    );
  }
}
