import 'package:flutter/material.dart';

import '../main.dart';
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
  final _password = TextEditingController();
  String _stage = 'prep';
  int _level = 2;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Student Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppErrorBox(message: _error),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Student name')),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _stage,
              decoration: const InputDecoration(labelText: 'Stage'),
              items: const [
                DropdownMenuItem(value: 'primary', child: Text('Primary')),
                DropdownMenuItem(value: 'prep', child: Text('Preparatory')),
                DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
              ],
              onChanged: (value) => setState(() => _stage = value ?? 'prep'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Level / Grade'),
              items: List.generate(6, (i) => i + 1)
                  .map((v) => DropdownMenuItem(value: v, child: Text('Level $v')))
                  .toList(),
              onChanged: (value) => setState(() => _level = value ?? 2),
            ),
            const SizedBox(height: 16),
            LoadingButton(loading: _loading, onPressed: _register, label: 'Register', icon: Icons.person_add_alt_1),
          ],
        ),
      ),
    );
  }
}
