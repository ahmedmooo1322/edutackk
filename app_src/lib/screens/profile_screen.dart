import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';
import '../widgets/app_error_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _student;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = AppScope.of(context).apiClient;
    final me = await api.me();
    final profile = await api.studentProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (me.ok) _user = me.data?['user'] as Map<String, dynamic>?;
      if (profile.ok) _student = profile.data?['student'] as Map<String, dynamic>?;
      _error = [if (!me.ok) me.error, if (!profile.ok) profile.error].whereType<String>().join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    final user = _user ?? const <String, dynamic>{};
    final student = _student ?? (user['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final stage = student['stage']?.toString() ?? '';
    final level = int.tryParse('${student['level'] ?? 1}') ?? 1;
    final weak = student['weak_topics']?.toString() ?? '[]';
    final strong = student['strong_topics']?.toString() ?? '[]';

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AppErrorBox(message: _error),
                    _InfoTile(label: context.tr('studentId'), value: '${user['id'] ?? student['user_id'] ?? '-'}'),
                    _InfoTile(label: context.tr('publicId'), value: '${user['public_id'] ?? student['public_id'] ?? '-'}'),
                    _InfoTile(label: context.tr('name'), value: '${user['name'] ?? student['name'] ?? '-'}'),
                    _InfoTile(label: context.tr('email'), value: '${user['email'] ?? student['email'] ?? '-'}'),
                    _InfoTile(label: context.tr('role'), value: '${user['role'] ?? student['role'] ?? '-'}'),
                    _InfoTile(label: context.tr('accountStatus'), value: '${user['status'] ?? student['status'] ?? '-'}'),
                    _InfoTile(label: context.tr('stage'), value: stageLabel(stage, lang)),
                    _InfoTile(label: context.tr('levelGrade'), value: gradeLabel(stage, level, lang)),
                    _InfoTile(label: context.tr('preferredLanguage'), value: '${user['preferred_language'] ?? '-'}'),
                    _InfoTile(label: context.tr('overallRate'), value: '${student['overall_rate'] ?? 0}%'),
                    _InfoTile(label: context.tr('questionsAsked'), value: '${student['total_questions_asked'] ?? 0}'),
                    _InfoTile(label: context.tr('quizzes'), value: '${student['total_quizzes_answered'] ?? 0}/${student['total_quizzes_received'] ?? 0}'),
                    _InfoTile(label: context.tr('correctAnswers'), value: '${student['correct_answers_count'] ?? 0}'),
                    _InfoTile(label: context.tr('strongTopics'), value: strong),
                    _InfoTile(label: context.tr('weakTopics'), value: weak),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: SelectableText(value.isEmpty ? '-' : value),
      ),
    );
  }
}
