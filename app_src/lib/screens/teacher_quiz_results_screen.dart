import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/student_avatar.dart';

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

  Future<void> _gradeAnswer(Map<String, dynamic> answer) async {
    final points = TextEditingController(text: '${answer['points_awarded'] ?? answer['points'] ?? ''}');
    final feedback = TextEditingController(text: '${answer['teacher_feedback'] ?? ''}');
    bool? correct = answer['is_correct'] == null ? null : (answer['is_correct'] == true || answer['is_correct'] == 1);
    final ok = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      title: Text(context.tr('manualGrade')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: correct == null ? 'partial' : (correct == true ? 'correct' : 'wrong'),
          decoration: InputDecoration(labelText: context.tr('markAnswer')),
          items: [
            DropdownMenuItem(value: 'correct', child: Text(context.tr('correct'))),
            DropdownMenuItem(value: 'wrong', child: Text(context.tr('wrong'))),
            DropdownMenuItem(value: 'partial', child: Text(context.tr('partial'))),
          ],
          onChanged: (v) => setLocal(() { correct = v == 'partial' ? null : v == 'correct'; }),
        ),
        TextField(controller: points, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('points'))),
        TextField(controller: feedback, minLines: 2, maxLines: 5, decoration: InputDecoration(labelText: context.tr('teacherFeedback'))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('save')))],
    )));
    if (ok != true) return;
    final answerId = int.tryParse('${answer['id']}') ?? 0;
    final res = await AppScope.of(context).apiClient.teacherGradeAnswer(_quizId, answerId, {
      'is_correct': correct,
      'points_awarded': num.tryParse(points.text.trim()),
      'teacher_feedback': feedback.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.ok ? context.tr('saved') : (res.error ?? context.tr('connectionProblem')))));
    if (res.ok) _load();
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
              if ((a['teacher_feedback'] ?? '').toString().isNotEmpty) Text('${context.tr('teacherFeedback')}: ${a['teacher_feedback']}'),
              Align(alignment: AlignmentDirectional.centerEnd, child: OutlinedButton.icon(onPressed: () => _gradeAnswer(a), icon: const Icon(Icons.check_circle_outline), label: Text(context.tr('manualGrade')))),
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
              leading: StudentAvatar(avatarUrl: s['avatar_url']?.toString(), name: '${s['student_name'] ?? '?'}'),
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
