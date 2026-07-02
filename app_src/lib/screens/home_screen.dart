import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/app_error_box.dart';

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
        _error = '';
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
    final profile = (user['profile'] as Map<String, dynamic>?) ?? const {};
    final name = user['name']?.toString() ?? 'Student';
    final plan = (profile['plan'] as Map<String, dynamic>?) ?? const {};
    final active = plan['active'] == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTrack'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings)),
          IconButton(onPressed: _logout, tooltip: context.tr('logout'), icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AppErrorBox(message: _error),
                    Text('${context.tr('welcome')}, $name', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(context.tr('chooseAction')),
                    const SizedBox(height: 14),
                    if (!active)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(context.tr('freePlanNote')),
                      ),
                    const SizedBox(height: 18),
                    _HomeCard(
                      icon: Icons.chat_bubble_outline,
                      title: context.tr('askAiTeacher'),
                      subtitle: context.tr('askAiSubtitle'),
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                    _HomeCard(
                      icon: Icons.person_outline,
                      title: context.tr('profile'),
                      subtitle: context.tr('profileSubtitle'),
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    _HomeCard(
                      icon: Icons.workspace_premium_outlined,
                      title: context.tr('subscription'),
                      subtitle: context.tr('subscriptionSubtitle'),
                      onTap: () => Navigator.pushNamed(context, '/subscription'),
                    ),
                  ],
                ),
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
