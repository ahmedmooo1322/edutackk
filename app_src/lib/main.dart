import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/chat_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/level_room_screen.dart';
import 'screens/login_screen.dart';
import 'screens/message_requests_screen.dart';
import 'screens/private_chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/student_search_screen.dart';
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
  final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    language.value = await widget.sessionStore.getLanguageCode();
    darkMode.value = await widget.sessionStore.getDarkMode();
  }

  Future<void> setLanguage(String code) async {
    final value = code == 'en' ? 'en' : 'ar';
    await widget.sessionStore.setLanguageCode(value);
    language.value = value;
  }

  Future<void> setDarkMode(bool value) async {
    await widget.sessionStore.setDarkMode(value);
    darkMode.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: language,
      builder: (context, lang, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: darkMode,
          builder: (context, isDark, _) {
            return AppScope(
              sessionStore: widget.sessionStore,
              apiClient: apiClient,
              languageCode: lang,
              darkMode: isDark,
              setLanguage: setLanguage,
              setDarkMode: setDarkMode,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: AppConfig.appName,
                builder: (context, child) => Directionality(
                  textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                ),
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
                  useMaterial3: true,
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF60A5FA), brightness: Brightness.dark),
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
                  '/level-room': (_) => const LevelRoomScreen(),
                  '/student-search': (_) => const StudentSearchScreen(),
                  '/friends': (_) => const FriendRequestsScreen(),
                  '/private-chat': (_) => const PrivateChatScreen(),
                  '/inbox': (_) => const InboxScreen(),
                  '/message-requests': (_) => const MessageRequestsScreen(),
                  '/subscription': (_) => const SubscriptionScreen(),
                  '/profile': (_) => const ProfileScreen(),
                  '/settings': (_) => const SettingsScreen(),
                },
              ),
            );
          },
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
    required this.darkMode,
    required this.setLanguage,
    required this.setDarkMode,
  });

  final SessionStore sessionStore;
  final ApiClient apiClient;
  final String languageCode;
  final bool darkMode;
  final Future<void> Function(String code) setLanguage;
  final Future<void> Function(bool value) setDarkMode;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) =>
      oldWidget.languageCode != languageCode || oldWidget.darkMode != darkMode;
}
