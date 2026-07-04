import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../i18n/app_strings.dart';
import '../main.dart';
import '../widgets/edutrack_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _goNext(AppScope.of(context));
  }

  Future<void> _goNext(AppScope scope) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    try {
      final token = await scope.sessionStore.getToken();
      final summary = await scope.sessionStore.getUserSummary();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        final isAdmin = summary['role'] == 'admin';
        final adminMode = isAdmin ? await scope.sessionStore.getAdminPreferredMode() : 'normal';
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(isAdmin && adminMode != 'normal' ? '/admin' : '/home');
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EduTrackLogo(size: 88),
            const SizedBox(height: 18),
            Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(context.tr('appSubtitle')),
            const SizedBox(height: 26),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
