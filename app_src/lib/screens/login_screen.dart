import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';
import '../widgets/edutrack_logo.dart';
import '../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final api = AppScope.of(context).apiClient;
    final result = await api.login(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.ok) {
      setState(() => _error = result.error ?? 'Login failed');
      return;
    }
    final summary = await AppScope.of(context).sessionStore.getUserSummary();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(summary['role'] == 'admin' ? '/admin' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings))]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: EduTrackLogo(size: 78)),
            const SizedBox(height: 12),
            Text(AppConfig.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(context.tr('loginContinue'), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            AppErrorBox(message: _error),
            TextField(controller: _email, decoration: InputDecoration(labelText: context.tr('loginIdentifier')), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: InputDecoration(labelText: context.tr('password')), obscureText: true),
            const SizedBox(height: 16),
            LoadingButton(loading: _loading, onPressed: _login, label: context.tr('login'), icon: Icons.login),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register', arguments: 'student'),
              child: Text(context.tr('createStudentAccount')),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/register', arguments: 'teacher'),
              icon: const Icon(Icons.school_outlined),
              label: Text(context.tr('createTeacherAccount')),
            ),
          ],
        ),
      ),
    );
  }
}
