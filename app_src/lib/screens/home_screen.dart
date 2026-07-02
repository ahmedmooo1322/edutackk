import 'package:flutter/material.dart';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _me;
  String _error = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AppScope.of(context).apiClient.me();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _me = result.data;
      } else {
        _error = result.error ?? 'Could not load account';
      }
    });
  }

  Future<void> _logout() async {
    await AppScope.of(context).apiClient.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = (_me?['user'] as Map<String, dynamic>?) ?? const {};
    final name = user['name']?.toString() ?? 'Student';
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTrack'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  Text('Welcome, $name', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  const Text('Choose what you want to do now.'),
                  const SizedBox(height: 24),
                  _HomeCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Ask AI Teacher',
                    subtitle: 'Send a question and wait for the answer.',
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  _HomeCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Subscription',
                    subtitle: 'Check if the account is active.',
                    onTap: () => Navigator.pushNamed(context, '/subscription'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
