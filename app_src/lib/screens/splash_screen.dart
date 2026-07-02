import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 500));
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
            const Icon(Icons.school_rounded, size: 72),
            const SizedBox(height: 16),
            Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(AppConfig.appSubtitle),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
