import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

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
  String _title = '';
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _conversationId = int.tryParse('${args['conversation_id'] ?? ''}') ?? 0;
      _title = '${args['name'] ?? context.tr('privateMessage')}';
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
    final res = await AppScope.of(context).apiClient.privateMessages(_conversationId, limit: 20);
    if (!mounted) return;
    setState(() {
      _loading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title.isEmpty ? context.tr('privateMessage') : _title), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
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
                            return _PrivateBubble(message: _messages[index - 1]);
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
  const _PrivateBubble({required this.message});

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
            Text(sender, style: Theme.of(context).textTheme.labelLarge),
            if (text.isNotEmpty) SelectableText(text),
            if (attachment != null) Text('📎 ${attachment['original_name'] ?? 'file'}'),
          ],
        ),
      ),
    );
  }
}
