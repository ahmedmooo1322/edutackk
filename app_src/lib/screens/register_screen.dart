import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../models/grade_options.dart';
import '../widgets/app_error_box.dart';
import '../widgets/loading_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _subjects = TextEditingController();
  String _role = 'student';
  bool _loadedRoleArgument = false;
  String _countryCode = 'EG';
  String _stage = 'primary';
  int _level = 1;
  bool _loading = false;
  String _error = '';


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRoleArgument) return;
    _loadedRoleArgument = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final role = args is String ? args : (args is Map ? args['role']?.toString() : null);
    if (role == 'teacher' || role == 'student') {
      _role = role!;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    _subjects.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await AppScope.of(context).apiClient.registerStudent(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          countryCode: _countryCode,
          educationSystem: educationSystemForCountry(_countryCode),
          username: _username.text,
          password: _password.text,
          stage: _stage,
          level: _level,
          role: _role,
          subjects: _subjects.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.ok) {
      setState(() => _error = result.error ?? 'Register failed');
      return;
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).languageCode;
    final country = countryByCode(_countryCode);
    final stages = stagesForCountry(_countryCode);
    if (!stages.any((s) => s.code == _stage)) _stage = stages.first.code;
    final levels = levelsForStage(_stage, countryCode: _countryCode);
    if (!levels.contains(_level)) _level = levels.first;
    return Scaffold(
      appBar: AppBar(title: Text(_role == 'teacher' ? context.tr('createTeacherAccount') : context.tr('createStudentAccount'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppErrorBox(message: _error),
            TextField(controller: _name, decoration: InputDecoration(labelText: _role == 'teacher' ? context.tr('teacherName') : context.tr('studentName'))),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: InputDecoration(labelText: context.tr('email')), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: InputDecoration(labelText: context.tr('phone')), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _username, decoration: InputDecoration(labelText: context.tr('username'), helperText: 'a-z, 0-9, _'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: InputDecoration(labelText: context.tr('password')), obscureText: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(labelText: context.tr('accountType')),
              items: [
                DropdownMenuItem(value: 'student', child: Text(context.tr('student'))),
                DropdownMenuItem(value: 'teacher', child: Text(context.tr('teacher'))),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'student'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _countryCode,
              decoration: const InputDecoration(labelText: 'Country / الدولة'),
              items: countryOptions
                  .map((c) => DropdownMenuItem(value: c.code, child: Text('${lang == 'ar' ? c.nameAr : c.nameEn}  ${c.dialCode}')))
                  .toList(),
              onChanged: (value) {
                final next = value ?? 'EG';
                final nextStages = stagesForCountry(next);
                setState(() {
                  _countryCode = next;
                  _stage = nextStages.first.code;
                  _level = levelsForStage(_stage, countryCode: next).first;
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Phone format: ${country.dialCode}...', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (_role == 'teacher') ...[
              TextField(controller: _subjects, decoration: InputDecoration(labelText: context.tr('teacherSubjects'), helperText: context.tr('subjectsHelp'))),
              const SizedBox(height: 16),
            ],
            if (_role == 'student') DropdownButtonFormField<String>(
              value: _stage,
              decoration: InputDecoration(labelText: context.tr('stage')),
              items: stages
                  .map((stage) => DropdownMenuItem(value: stage.code, child: Text(lang == 'ar' ? stage.nameAr : stage.nameEn)))
                  .toList(),
              onChanged: (value) {
                final next = value ?? 'prep';
                setState(() {
                  _stage = next;
                  _level = levelsForStage(next, countryCode: _countryCode).first;
                });
              },
            ),
            if (_role == 'student') const SizedBox(height: 12),
            if (_role == 'student') DropdownButtonFormField<int>(
              value: _level,
              decoration: InputDecoration(labelText: context.tr('levelGrade')),
              items: levels.map((level) => DropdownMenuItem(value: level, child: Text(gradeLabel(_stage, level, lang, countryCode: _countryCode)))).toList(),
              onChanged: (value) => setState(() => _level = value ?? 1),
            ),
            const SizedBox(height: 16),
            LoadingButton(loading: _loading, onPressed: _register, label: context.tr('register'), icon: Icons.person_add_alt_1),
          ],
        ),
      ),
    );
  }
}
