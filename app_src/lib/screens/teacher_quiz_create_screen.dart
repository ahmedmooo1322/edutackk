import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';

class TeacherQuizCreateScreen extends StatefulWidget {
  const TeacherQuizCreateScreen({super.key});

  @override
  State<TeacherQuizCreateScreen> createState() => _TeacherQuizCreateScreenState();
}

class _QuizQuestionDraft {
  _QuizQuestionDraft({this.type = 'written', String text = ''}) {
    this.text.text = text;
  }

  final text = TextEditingController();
  String type;
  final List<TextEditingController> choices = [TextEditingController(), TextEditingController()];
  int correctIndex = 0;

  void dispose() {
    text.dispose();
    for (final c in choices) {
      c.dispose();
    }
  }
}

class _TeacherQuizCreateScreenState extends State<TeacherQuizCreateScreen> {
  final _title = TextEditingController();
  final _timer = TextEditingController();
  String _countryCode = 'EG';
  String _stage = stagesForCountry('EG').first.code;
  int _level = stagesForCountry('EG').first.minLevel;
  String _scoringMode = 'automatic';
  bool _loadingStudents = false;
  bool _submitting = false;
  bool _argsLoaded = false;
  int? _quizId;
  String _error = '';
  final List<Map<String, dynamic>> _students = [];
  final Set<int> _selectedStudents = {};
  final List<_QuizQuestionDraft> _questions = [_QuizQuestionDraft()];

  bool get _isEditing => _quizId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final quiz = (args['quiz'] is Map) ? Map<String, dynamic>.from(args['quiz'] as Map) : <String, dynamic>{};
      _quizId = int.tryParse('${args['quiz_id'] ?? quiz['id'] ?? ''}');
      if (quiz.isNotEmpty) _applyQuizData(quiz);
    }
  }

  void _applyQuizData(Map<String, dynamic> quiz) {
    _title.text = '${quiz['title'] ?? ''}';
    final timer = quiz['timer_minutes'] ?? quiz['timer'] ?? '';
    if ('$timer'.isNotEmpty && '$timer' != 'null') _timer.text = '$timer';
    final country = '${quiz['country_code'] ?? quiz['target_country_code'] ?? 'EG'}';
    _countryCode = country.isEmpty || country == 'null' ? 'EG' : country;
    final availableStages = stagesForCountry(_countryCode);
    final stage = '${quiz['stage'] ?? quiz['target_stage'] ?? availableStages.first.code}';
    _stage = availableStages.any((s) => s.code == stage) ? stage : availableStages.first.code;
    final availableLevels = levelsForStage(_stage, countryCode: _countryCode);
    final parsedLevel = int.tryParse('${quiz['level'] ?? quiz['target_level'] ?? availableLevels.first}') ?? availableLevels.first;
    _level = availableLevels.contains(parsedLevel) ? parsedLevel : availableLevels.first;
    final scoring = '${quiz['scoring_mode'] ?? _scoringMode}';
    if (scoring == 'automatic' || scoring == 'manual') _scoringMode = scoring;

    final rawQuestions = quiz['questions'];
    if (rawQuestions is List && rawQuestions.isNotEmpty) {
      for (final q in _questions) {
        q.dispose();
      }
      _questions
        ..clear()
        ..addAll(rawQuestions.whereType<Map>().map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final draft = _QuizQuestionDraft(
            type: '${item['question_type'] ?? item['type'] ?? 'written'}',
            text: '${item['question_text'] ?? item['text'] ?? ''}',
          );
          final choices = item['choices'];
          if (choices is List && choices.isNotEmpty) {
            for (final c in draft.choices) {
              c.dispose();
            }
            draft.choices.clear();
            var correct = 0;
            for (final entry in choices.asMap().entries) {
              final choice = entry.value is Map ? Map<String, dynamic>.from(entry.value as Map) : {'choice_text': '${entry.value}'};
              final controller = TextEditingController(text: '${choice['choice_text'] ?? choice['text'] ?? ''}');
              draft.choices.add(controller);
              if (choice['is_correct'] == true) correct = entry.key;
            }
            while (draft.choices.length < 2) {
              draft.choices.add(TextEditingController());
            }
            draft.correctIndex = correct < 0 ? 0 : (correct >= draft.choices.length ? draft.choices.length - 1 : correct);
          }
          return draft;
        }));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _timer.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() { _loadingStudents = true; _error = ''; });
    final res = await AppScope.of(context).apiClient.teacherStudents(countryCode: _countryCode, stage: _stage, level: _level);
    if (!mounted) return;
    setState(() {
      _loadingStudents = false;
      _students.clear();
      _selectedStudents.clear();
      if (res.ok) {
        _students.addAll((res.data?['students'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = res.error ?? context.tr('connectionProblem');
      }
    });
  }

  void _addQuestion(String type) => setState(() => _questions.add(_QuizQuestionDraft(type: type)));

  Future<void> _removeQuestion(int index) async {
    if (_questions.length <= 1) return;
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(context.tr('removeQuestion')),
      content: Text(context.tr('removeQuestionConfirm')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('removeQuestion')))],
    ));
    if (ok != true) return;
    setState(() {
      final q = _questions.removeAt(index);
      q.dispose();
    });
  }

  Map<String, dynamic> _questionBody(_QuizQuestionDraft q) {
    final base = {'question_type': q.type, 'question_text': q.text.text.trim(), 'points': 1};
    if (q.type == 'mcq') {
      base['choices'] = q.choices.asMap().entries
          .map((e) => {'choice_text': e.value.text.trim(), 'is_correct': e.key == q.correctIndex})
          .where((c) => (c['choice_text'] as String).isNotEmpty)
          .toList();
    }
    return base;
  }

  Map<String, dynamic> _buildBody({required bool publish}) {
    return {
      'title': _title.text.trim().isEmpty ? context.tr('quiz') : _title.text.trim(),
      'country_code': _countryCode,
      'target_country_code': _countryCode,
      'education_system': educationSystemForCountry(_countryCode),
      'stage': _stage,
      'target_stage': _stage,
      'level': _level,
      'target_level': _level,
      'timer_minutes': int.tryParse(_timer.text.trim()),
      'student_ids': _selectedStudents.toList(),
      'randomize_questions': true,
      'randomize_choices': true,
      'scoring_mode': _scoringMode,
      'status': publish ? 'published' : 'draft',
      'publish': publish,
      'questions': _questions.map(_questionBody).toList(),
    };
  }

  Future<void> _saveDraft() async {
    await _submit(publish: false);
  }

  Future<void> _publishQuiz() async {
    if (_selectedStudents.isEmpty) {
      setState(() => _error = context.tr('chooseStudents'));
      return;
    }
    await _submit(publish: true);
  }

  Future<void> _submit({required bool publish}) async {
    final body = _buildBody(publish: publish);
    setState(() { _submitting = true; _error = ''; });
    final api = AppScope.of(context).apiClient;
    final res = _isEditing
        ? (publish ? await api.teacherPublishQuiz(_quizId!, body) : await api.teacherUpdateQuiz(_quizId!, body))
        : await api.teacherCreateQuiz(body);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publish ? context.tr('quizPublished') : context.tr('draftSaved'))));
      Navigator.pop(context);
    } else {
      setState(() => _error = res.error ?? context.tr('connectionProblem'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    final countries = countryOptions;
    final stages = stagesForCountry(_countryCode);
    if (!stages.any((s) => s.code == _stage)) _stage = stages.first.code;
    final levels = levelsForStage(_stage, countryCode: _countryCode);
    if (!levels.contains(_level)) _level = levels.first;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? context.tr('editQuiz') : context.tr('addQuiz'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextField(controller: _title, decoration: InputDecoration(labelText: context.tr('quizTitle'))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _countryCode,
              decoration: InputDecoration(labelText: context.tr('country')),
              items: countries.map((c) => DropdownMenuItem(value: c.code, child: Text(lang == 'ar' ? '${c.nameAr} (${c.dialCode})' : '${c.nameEn} (${c.dialCode})'))).toList(),
              onChanged: (v) {
                setState(() {
                  _countryCode = v ?? 'EG';
                  final firstStage = stagesForCountry(_countryCode).first;
                  _stage = firstStage.code;
                  _level = firstStage.minLevel;
                });
                _loadStudents();
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: _stage, decoration: InputDecoration(labelText: context.tr('stage')), items: stages.map((s) => DropdownMenuItem(value: s.code, child: Text(lang == 'ar' ? s.nameAr : s.nameEn))).toList(), onChanged: (v) { setState(() { _stage = v ?? stages.first.code; _level = levelsForStage(_stage, countryCode: _countryCode).first; }); _loadStudents(); })),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<int>(value: _level, decoration: InputDecoration(labelText: context.tr('levelGrade')), items: levels.map((l) => DropdownMenuItem(value: l, child: Text(gradeLabel(_stage, l, lang, countryCode: _countryCode)))).toList(), onChanged: (v) { setState(() => _level = v ?? levels.first); _loadStudents(); })),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _timer, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('timerMinutes'), helperText: context.tr('timerMax'))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _scoringMode,
              decoration: InputDecoration(labelText: context.tr('scoringMode')),
              items: [
                DropdownMenuItem(value: 'automatic', child: Text(context.tr('automaticScoring'))),
                DropdownMenuItem(value: 'manual', child: Text(context.tr('manualScoring'))),
              ],
              onChanged: (v) => setState(() => _scoringMode = v ?? 'automatic'),
            ),
            const SizedBox(height: 18),
            Text(context.tr('questions'), style: Theme.of(context).textTheme.titleLarge),
            ..._questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [Expanded(child: Text('${context.tr('question')} ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: _questions.length <= 1 ? null : () => _removeQuestion(i), icon: const Icon(Icons.delete_outline)), DropdownButton<String>(value: q.type, items: [DropdownMenuItem(value: 'written', child: Text(context.tr('written'))), DropdownMenuItem(value: 'mcq', child: Text(context.tr('mcq')))], onChanged: (v) => setState(() => q.type = v ?? 'written'))]),
                TextField(controller: q.text, decoration: InputDecoration(labelText: context.tr('questionText'))),
                if (q.type == 'mcq') ...[
                  const SizedBox(height: 8),
                  ...q.choices.asMap().entries.map((e) => Row(children: [Radio<int>(value: e.key, groupValue: q.correctIndex, onChanged: (v) => setState(() => q.correctIndex = v ?? 0)), Expanded(child: TextField(controller: e.value, decoration: InputDecoration(labelText: '${context.tr('choice')} ${e.key + 1}')))])),
                  TextButton.icon(onPressed: () => setState(() => q.choices.add(TextEditingController())), icon: const Icon(Icons.add), label: Text(context.tr('addChoice'))),
                ],
              ])));
            }),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _addQuestion('written'), icon: const Icon(Icons.edit), label: Text(context.tr('addWritten')))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () => _addQuestion('mcq'), icon: const Icon(Icons.check_circle_outline), label: Text(context.tr('addMcq'))))]),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: Text(context.tr('chooseStudents'), style: Theme.of(context).textTheme.titleLarge)), TextButton(onPressed: () => setState(() { if (_selectedStudents.length == _students.length) { _selectedStudents.clear(); } else { _selectedStudents.addAll(_students.map((s) => int.tryParse('${s['id']}') ?? 0).where((id) => id > 0)); } }), child: Text(context.tr('selectAll')))]),
            if (_loadingStudents) const Center(child: CircularProgressIndicator()),
            ..._students.map((s) { final id = int.tryParse('${s['id']}') ?? 0; return CheckboxListTile(value: _selectedStudents.contains(id), onChanged: (v) => setState(() => v == true ? _selectedStudents.add(id) : _selectedStudents.remove(id)), title: Text('${s['name'] ?? ''}'), subtitle: Text('@${s['username'] ?? ''}')); }),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _submitting ? null : _saveDraft, icon: const Icon(Icons.save_outlined), label: Text(context.tr('saveDraft')))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _submitting ? null : _publishQuiz, icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), label: Text(context.tr('publishQuiz')))),
            ]),
          ],
        ),
      ),
    );
  }
}
