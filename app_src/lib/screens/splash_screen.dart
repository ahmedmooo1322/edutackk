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
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final token = await AppScope.of(context).sessionStore.getToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(token == null ? '/login' : '/home');
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
