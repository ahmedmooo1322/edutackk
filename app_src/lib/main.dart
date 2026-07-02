import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';

void main() {
  runApp(EduTrackApp());
}

class EduTrackApp extends StatelessWidget {
  EduTrackApp({super.key});

  final SessionStore sessionStore = SessionStore();

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(sessionStore);
    return AppScope(
      sessionStore: sessionStore,
      apiClient: apiClient,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/chat': (_) => const ChatScreen(),
          '/subscription': (_) => const SubscriptionScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required super.child,
    required this.sessionStore,
    required this.apiClient,
  });

  final SessionStore sessionStore;
  final ApiClient apiClient;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) => false;
}
