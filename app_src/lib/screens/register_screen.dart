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
  String _stage = 'prep';
  int _level = 1;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
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
          username: _username.text,
          password: _password.text,
          stage: _stage,
          level: _level,
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
    final levels = levelsForStage(_stage);
    if (!levels.contains(_level)) _level = levels.first;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('createStudentAccount'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppErrorBox(message: _error),
            TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('studentName'))),
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
              value: _stage,
              decoration: InputDecoration(labelText: context.tr('stage')),
              items: stageOptions
                  .map((stage) => DropdownMenuItem(value: stage.code, child: Text(lang == 'ar' ? stage.nameAr : stage.nameEn)))
                  .toList(),
              onChanged: (value) {
                final next = value ?? 'prep';
                setState(() {
                  _stage = next;
                  _level = levelsForStage(next).first;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _level,
              decoration: InputDecoration(labelText: context.tr('levelGrade')),
              items: levels.map((level) => DropdownMenuItem(value: level, child: Text(gradeLabel(_stage, level, lang)))).toList(),
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
