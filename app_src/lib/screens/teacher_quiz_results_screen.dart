import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';

class TeacherQuizResultsScreen extends StatefulWidget {
  const TeacherQuizResultsScreen({super.key});

  @override
  State<TeacherQuizResultsScreen> createState() => _TeacherQuizResultsScreenState();
}

class _TeacherQuizResultsScreenState extends State<TeacherQuizResultsScreen> {
  int _quizId = 0;
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _quiz = {};
  final List<Map<String, dynamic>> _students = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quizId == 0) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) _quizId = int.tryParse('${args['quiz_id']}') ?? 0;
      _load();
    }
  }

  Future<void> _load() async {
    final res = await AppScope.of(context).apiClient.teacherQuizResults(_quizId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _quiz = Map<String, dynamic>.from(res.data?['quiz'] as Map? ?? const {});
        _students
          ..clear()
          ..addAll((res.data?['students'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? context.tr('connectionProblem');
      }
    });
  }

  void _showStudentAnswers(Map<String, dynamic> student) {
    final answers = (student['answers'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text('${student['student_name'] ?? ''}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${context.tr('score')}: ${student['score'] ?? '-'} / ${student['total_points'] ?? '-'}'),
            const Divider(),
            if (answers.isEmpty) Text(context.tr('noResults')),
            ...answers.map((a) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${a['question_text'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('${context.tr('writtenAnswer')}: ${a['written_answer'] ?? a['selected_choice_text'] ?? '-'}'),
              Text('${context.tr('score')}: ${a['points_awarded'] ?? '-'} / ${a['points'] ?? '-'}'),
            ])))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('quizResults'))),
      body: SafeArea(
        child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            Text('${_quiz['title'] ?? context.tr('quiz')}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._students.map((s) => Card(child: ListTile(
              leading: CircleAvatar(child: Text(('${s['student_name'] ?? '?'}'.isNotEmpty ? '${s['student_name'] ?? '?'}'[0] : '?'))),
              title: Text('${s['student_name'] ?? ''}'),
              subtitle: Text('${s['status'] ?? ''} • ${context.tr('score')}: ${s['score'] ?? '-'} / ${s['total_points'] ?? '-'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showStudentAnswers(s),
            ))),
          ],
        ),
      ),
    );
  }
}
