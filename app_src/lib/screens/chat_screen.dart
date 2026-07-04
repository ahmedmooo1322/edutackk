import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  bool _loading = true;
  bool _loadingMore = false;
  String _status = '';
  int? _remaining;
  int? _dailyLimit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _friendlyConnectionError => context.tr('connectionProblem');

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _status = '';
    });
    final api = AppScope.of(context).apiClient;
    final history = await api.getAiChatHistory(limit: 20);
    final usage = await api.usage();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (history.ok) {
        final list = (history.data?['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _messages
          ..clear()
          ..addAll(list);
      } else {
        _status = _friendlyConnectionError;
      }
      final usageMap = usage.data?['usage'] as Map<String, dynamic>?;
      if (usageMap != null) {
        _remaining = int.tryParse('${usageMap['remaining_today'] ?? ''}');
        _dailyLimit = int.tryParse('${usageMap['daily_limit'] ?? ''}');
      }
    });
    _scrollToBottom(jump: true);
  }

  Future<void> _loadMore() async {
    if (_messages.isEmpty || _loadingMore) return;
    final firstId = _messages.first.id;
    if (firstId == null) return;
    setState(() => _loadingMore = true);
    final result = await AppScope.of(context).apiClient.getAiChatHistory(before: firstId, limit: 50);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (result.ok) {
        final older = (result.data?['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _messages.insertAll(0, older);
      } else {
        _status = _friendlyConnectionError;
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _status = context.tr('sendingQuestion');
      _messages.add(ChatMessage(role: ChatRole.user, text: text));
      _controller.clear();
    });
    _scrollToBottom();

    final api = AppScope.of(context).apiClient;
    final create = await api.startStudentChat(text);
    if (!mounted) return;
    if (!create.ok) {
      setState(() {
        _sending = false;
        _status = _friendlyConnectionError;
        _messages.add(ChatMessage(role: ChatRole.system, text: _friendlyConnectionError));
      });
      return;
    }

    final usage = create.data?['usage'];
    if (usage is Map<String, dynamic>) {
      _remaining = int.tryParse('${usage['remaining_today'] ?? ''}');
      _dailyLimit = int.tryParse('${usage['daily_limit'] ?? ''}');
    }
    final jobId = create.data?['job_id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      setState(() {
        _sending = false;
        _status = _friendlyConnectionError;
      });
      return;
    }

    setState(() => _status = context.tr('waitingAnswer'));
    await _pollJob(jobId);
  }

  Future<void> _pollJob(String jobId) async {
    final api = AppScope.of(context).apiClient;
    final started = DateTime.now();
    while (DateTime.now().difference(started) < const Duration(seconds: 90)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final result = await api.getJob(jobId);
      if (!mounted) return;
      if (!result.ok) {
        // Do not show raw SocketException/TimeoutException. Keep trying until total wait is reached.
        setState(() => _status = context.tr('waitingAnswer'));
        continue;
      }
      final job = result.data!;
      setState(() => _status = '${context.tr('jobStatus')}: ${job.status}');
      if (job.done) {
        setState(() {
          _sending = false;
          if (job.status == 'failed') {
            _messages.add(ChatMessage(role: ChatRole.system, text: _friendlyConnectionError));
          } else {
            _messages.add(ChatMessage(role: ChatRole.assistant, text: job.answer ?? context.tr('noAnswer')));
          }
          _status = '';
        });
        _scrollToBottom();
        return;
      }
    }
    setState(() {
      _sending = false;
      _status = _friendlyConnectionError;
      _messages.add(ChatMessage(role: ChatRole.system, text: _friendlyConnectionError));
    });
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final usageLine = _remaining == null
        ? ''
        : '${context.tr('remainingToday')}: $_remaining ${context.tr('messages')}${_dailyLimit == null ? '' : ' / $_dailyLimit'}';
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('aiTeacher')),
        actions: [
          IconButton(
            tooltip: scope.darkMode ? context.tr('lightMode') : context.tr('darkMode'),
            onPressed: () => scope.setDarkMode(!scope.darkMode),
            icon: Icon(scope.darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(onPressed: _loadInitial, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_status.isNotEmpty || usageLine.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text([_status, usageLine].where((x) => x.isNotEmpty).join('\n')),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(child: Text(context.tr('askFirst')))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Center(
                                child: TextButton.icon(
                                  onPressed: _loadingMore ? null : _loadMore,
                                  icon: _loadingMore
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.history),
                                  label: Text(context.tr('loadMore')),
                                ),
                              );
                            }
                            return _MessageBubble(message: _messages[index - 1]);
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(hintText: context.tr('typeQuestion')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending || _remaining == 0 ? null : _send,
                    icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextDirection _messageDirection(String text) {
  final rtl = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  return rtl ? TextDirection.rtl : TextDirection.ltr;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isSystem = message.role == ChatRole.system;
    final colorScheme = Theme.of(context).colorScheme;
    final direction = _messageDirection(message.text);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSystem
                ? colorScheme.errorContainer
                : isUser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Directionality(
            textDirection: direction,
            child: SelectableText(
              message.text,
              textAlign: direction == TextDirection.rtl ? TextAlign.right : TextAlign.left,
              textDirection: direction,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
          ),
        ),
      ),
    );
  }
}
