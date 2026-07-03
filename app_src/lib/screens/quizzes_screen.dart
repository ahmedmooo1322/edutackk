import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _loading = true;
  String _role = 'student';
  String _error = '';
  final List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    final scope = AppScope.of(context);
    final summary = await scope.sessionStore.getUserSummary();
    final role = summary['role'] ?? 'student';
    final res = role == 'teacher' ? await scope.apiClient.teacherQuizzes() : await scope.apiClient.quizzes();
    if (!mounted) return;
    setState(() {
      _role = role;
      _loading = false;
      if (res.ok) {
        _quizzes
          ..clear()
          ..addAll((res.data?['quizzes'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? context.tr('connectionProblem');
      }
    });
  }

  Future<void> _endQuiz(int id) async {
    final res = await AppScope.of(context).apiClient.teacherEndQuiz(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('saved') : (res.error ?? 'Failed'))));
    if (res.ok) _load();
  }

  Future<void> _deleteQuiz(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(context.tr('deleteQuiz')),
      content: Text(context.tr('deleteQuizConfirm')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('deleteQuiz')))],
    ));
    if (ok != true) return;
    final res = await AppScope.of(context).apiClient.teacherDeleteQuiz(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('saved') : (res.error ?? 'Failed'))));
    if (res.ok) _load();
  }

  Widget _teacherView() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_quizzes.isEmpty) Text(context.tr('noQuizzes')),
              ..._quizzes.map((q) {
                final id = int.tryParse('${q['id']}') ?? 0;
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.quiz_outlined)),
                    title: Text('${q['title'] ?? context.tr('quiz')}'),
                    subtitle: Text('${q['status'] ?? ''} • ${q['submitted_count'] ?? 0}/${q['assigned_count'] ?? 0} ${context.tr('submitted')}'),
                    onTap: () => Navigator.pushNamed(context, '/teacher-quiz-results', arguments: {'quiz_id': id, 'title': q['title']?.toString()}).then((_) => _load()),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) { if (v == 'end') _endQuiz(id); if (v == 'delete') _deleteQuiz(id); },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'end', child: Text(context.tr('endQuiz'))),
                        PopupMenuItem(value: 'delete', child: Text(context.tr('deleteQuiz'))),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(child: FilledButton.icon(onPressed: () => Navigator.pushNamed(context, '/teacher-quiz-create').then((_) => _load()), icon: const Icon(Icons.add), label: Text(context.tr('addQuiz')))),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(context.tr('runningQuizzes'))),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _studentView() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_quizzes.isEmpty) Text(context.tr('noQuizzes')),
          ..._quizzes.map((q) {
            final id = int.tryParse('${q['id']}') ?? 0;
            final status = '${q['assignment_status'] ?? ''}';
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(status == 'submitted' ? Icons.check : Icons.assignment_outlined)),
                title: Text('${q['title'] ?? context.tr('quiz')}'),
                subtitle: Text('${q['teacher_name'] ?? ''} • ${status.isEmpty ? q['quiz_status'] : status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: status == 'submitted' ? null : () async {
                  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                    title: Text(context.tr('startQuiz')),
                    content: Text(context.tr('quizExitWarning')),
                    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('startQuiz')))],
                  ));
                  if (ok == true && mounted) Navigator.pushNamed(context, '/quiz-take', arguments: {'quiz_id': id, 'title': q['title']?.toString()}).then((_) => _load());
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('quizzes')), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator()) : (_role == 'teacher' ? _teacherView() : _studentView())),
    );
  }
}
