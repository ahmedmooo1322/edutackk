import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
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
  String _status = '';
  String _planLine = '';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
        _status = create.error ?? 'Could not create job.';
        _messages.add(ChatMessage(role: ChatRole.system, text: _status));
      });
      return;
    }

    final plan = create.data?['plan'];
    if (plan is Map<String, dynamic>) {
      _planLine = '${plan['name'] ?? ''} • ${context.tr('dailyLimit')}: ${plan['daily_ai_limit'] ?? '-'}';
    }
    final jobId = create.data?['job_id']?.toString();
    final retryMs = int.tryParse('${create.data?['retry_after_ms'] ?? AppConfig.defaultPollDelayMs}') ?? AppConfig.defaultPollDelayMs;
    if (jobId == null || jobId.isEmpty) {
      setState(() {
        _sending = false;
        _status = 'Server did not return job_id.';
      });
      return;
    }

    setState(() => _status = context.tr('waitingAnswer'));
    await _pollJob(jobId, retryMs);
  }

  Future<void> _pollJob(String jobId, int retryMs) async {
    final api = AppScope.of(context).apiClient;
    for (var i = 0; i < 80; i++) {
      await Future<void>.delayed(Duration(milliseconds: retryMs));
      if (!mounted) return;
      final result = await api.getJob(jobId);
      if (!mounted) return;
      if (!result.ok) {
        setState(() {
          _sending = false;
          _status = result.error ?? 'Could not poll job.';
          _messages.add(ChatMessage(role: ChatRole.system, text: _status));
        });
        _scrollToBottom();
        return;
      }
      final job = result.data!;
      setState(() => _status = '${context.tr('jobStatus')}: ${job.status}');
      if (job.done) {
        setState(() {
          _sending = false;
          if (job.status == 'failed') {
            _messages.add(ChatMessage(role: ChatRole.system, text: job.error ?? 'AI job failed.'));
          } else {
            _messages.add(ChatMessage(role: ChatRole.assistant, text: job.answer ?? 'No answer returned.'));
          }
          _status = '';
        });
        _scrollToBottom();
        return;
      }
    }
    setState(() {
      _sending = false;
      _status = context.tr('timeout');
      _messages.add(ChatMessage(role: ChatRole.system, text: _status));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('aiTeacher'))),
      body: SafeArea(
        child: Column(
          children: [
            if (_status.isNotEmpty || _planLine.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text([_status, _planLine].where((x) => x.isNotEmpty).join('\n')),
              ),
            Expanded(
              child: _messages.isEmpty
                  ? Center(child: Text(context.tr('askFirst')))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
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
                    onPressed: _sending ? null : _send,
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isSystem = message.role == ChatRole.system;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSystem
              ? colorScheme.errorContainer
              : isUser
                  ? colorScheme.primaryContainer
                  : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(message.text),
      ),
    );
  }
}
