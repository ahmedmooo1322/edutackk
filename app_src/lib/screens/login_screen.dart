import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';
import '../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'student@example.com');
  final _password = TextEditingController(text: 'password123');
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
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings))]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.school_rounded, size: 64),
            const SizedBox(height: 8),
            Text(AppConfig.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Login to continue learning', textAlign: TextAlign.center),
            const SizedBox(height: 28),
            AppErrorBox(message: _error),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            LoadingButton(loading: _loading, onPressed: _login, label: 'Login', icon: Icons.login),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Create student account')),
          ],
        ),
      ),
    );
  }
}
