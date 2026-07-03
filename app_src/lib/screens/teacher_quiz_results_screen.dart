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
            ))),
          ],
        ),
      ),
    );
  }
}
