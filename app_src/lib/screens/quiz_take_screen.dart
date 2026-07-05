import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

class QuizTakeScreen extends StatefulWidget {
  const QuizTakeScreen({super.key});

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  bool _loading = true;
  bool _submitting = false;
  bool _readOnly = false;
  String _error = '';
  int _quizId = 0;
  Map<String, dynamic> _assignment = {};
  final List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _choices = {};
  final Map<int, TextEditingController> _written = {};
  final Map<int, Map<String, dynamic>> _answerByQuestion = {};
  final Map<int, Map<String, dynamic>> _correctByQuestion = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quizId == 0) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _quizId = int.tryParse('${args['quiz_id']}') ?? 0;
        _readOnly = args['read_only'] == true;
      }
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    final api = AppScope.of(context).apiClient;
    final res = _readOnly ? await api.quizDetails(_quizId) : await api.startQuiz(_quizId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _assignment = Map<String, dynamic>.from(res.data?['assignment'] as Map? ?? const {});
        _readOnly = _readOnly || '${_assignment['status'] ?? ''}' == 'submitted' || '${_assignment['status'] ?? ''}' == 'ended';
        _questions
          ..clear()
          ..addAll((res.data?['questions'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        _answerByQuestion.clear();
        for (final a in (res.data?['answers'] as List? ?? const []).whereType<Map>()) {
          final map = Map<String, dynamic>.from(a);
          final qid = int.tryParse('${map['question_id']}') ?? 0;
          if (qid > 0) _answerByQuestion[qid] = map;
        }
        _correctByQuestion.clear();
        for (final c in (res.data?['correct_choices'] as List? ?? const []).whereType<Map>()) {
          final map = Map<String, dynamic>.from(c);
          final qid = int.tryParse('${map['question_id']}') ?? 0;
          if (qid > 0) _correctByQuestion[qid] = map;
        }
        for (final q in _questions) {
          final id = int.tryParse('${q['id']}') ?? 0;
          final existing = _answerByQuestion[id];
          if (existing != null) {
            final cid = int.tryParse('${existing['choice_id'] ?? 0}') ?? 0;
            if (cid > 0) _choices[id] = cid;
          }
          _written.putIfAbsent(id, () => TextEditingController(text: existing?['written_answer']?.toString() ?? ''));
        }
      } else {
        _error = res.error ?? context.tr('connectionProblem');
      }
    });
  }

  Future<bool> _confirmExit() async {
    if (_readOnly) return true;
    if (_submitting || _loading) return true;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(context.tr('leaveQuiz')),
      content: Text(context.tr('quizExitWarning')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('leaveQuiz')))],
    ));
    if (ok == true) {
      await AppScope.of(context).apiClient.abandonQuiz(_quizId);
      return true;
    }
    return false;
  }

  Future<void> _submit() async {
    final answers = _questions.map((q) {
      final id = int.tryParse('${q['id']}') ?? 0;
      if (q['question_type'] == 'mcq') return {'question_id': id, 'choice_id': _choices[id]};
      return {'question_id': id, 'written_answer': _written[id]?.text ?? ''};
    }).toList();
    setState(() { _submitting = true; _error = ''; });
    final res = await AppScope.of(context).apiClient.submitQuiz(_quizId, answers);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.ok) {
      final result = res.data?['result'] as Map?;
      await showDialog(context: context, builder: (_) => AlertDialog(title: Text(context.tr('submitted')), content: Text('${context.tr('score')}: ${result?['score'] ?? '-'} / ${result?['total_points'] ?? '-'}'), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('ok')))]));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _error = res.error ?? context.tr('connectionProblem'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(title: Text('${_assignment['title'] ?? context.tr('quiz')}')),
        body: SafeArea(
          child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_readOnly) Card(child: ListTile(leading: const Icon(Icons.lock_outline), title: Text(context.tr('alreadySubmittedQuiz')), subtitle: Text(context.tr('viewAnswers')))),
              if (_assignment['timer_minutes'] != null) Card(child: ListTile(leading: const Icon(Icons.timer), title: Text('${context.tr('timer')}: ${_assignment['timer_minutes']} ${context.tr('minutes')}'))),
              ..._questions.asMap().entries.map((entry) {
                final q = entry.value;
                final id = int.tryParse('${q['id']}') ?? 0;
                final choices = (q['choices'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
                final correct = _correctByQuestion[id];
                return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('${entry.key + 1}. ${q['question_text'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (q['question_type'] == 'mcq') ...choices.map((c) { final cid = int.tryParse('${c['id']}') ?? 0; return RadioListTile<int>(value: cid, groupValue: _choices[id], onChanged: _readOnly ? null : (v) => setState(() => _choices[id] = v ?? 0), title: Text('${c['choice_text'] ?? ''}')); }),
                  if (_readOnly && correct != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${context.tr('correctAnswers')}: ${correct['choice_text'] ?? ''}', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                  if (q['question_type'] != 'mcq') TextField(controller: _written[id], enabled: !_readOnly, minLines: 3, maxLines: 8, decoration: InputDecoration(labelText: context.tr('writtenAnswer'))),
                ])));
              }),
              const SizedBox(height: 12),
              if (!_readOnly) FilledButton.icon(onPressed: _submitting ? null : _submit, icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check), label: Text(context.tr('submitQuiz'))),
            ],
          ),
        ),
      ),
    );
  }
}
