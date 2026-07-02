import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EduTrackApp());
}

class EduTrackApp extends StatefulWidget {
  EduTrackApp({super.key});

  final SessionStore sessionStore = SessionStore();

  @override
  State<EduTrackApp> createState() => _EduTrackAppState();
}

class _EduTrackAppState extends State<EduTrackApp> {
  late final ApiClient apiClient = ApiClient(widget.sessionStore);
  final ValueNotifier<String> language = ValueNotifier<String>('ar');

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    language.value = await widget.sessionStore.getLanguageCode();
  }

  Future<void> setLanguage(String code) async {
    final value = code == 'en' ? 'en' : 'ar';
    await widget.sessionStore.setLanguageCode(value);
    language.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: language,
      builder: (context, lang, _) {
        return AppScope(
          sessionStore: widget.sessionStore,
          apiClient: apiClient,
          languageCode: lang,
          setLanguage: setLanguage,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConfig.appName,
            builder: (context, child) => Directionality(
              textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
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
              '/profile': (_) => const ProfileScreen(),
              '/settings': (_) => const SettingsScreen(),
            },
          ),
        );
      },
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required super.child,
    required this.sessionStore,
    required this.apiClient,
    required this.languageCode,
    required this.setLanguage,
  });

  final SessionStore sessionStore;
  final ApiClient apiClient;
  final String languageCode;
  final Future<void> Function(String code) setLanguage;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) => oldWidget.languageCode != languageCode;
}
