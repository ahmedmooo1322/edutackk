import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_state.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/reset_password_page.dart';
import 'features/game/domain/game.dart';
import 'features/game/presentation/game_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/profile/presentation/admin_page.dart';
import 'features/profile/presentation/misc_pages.dart';
import 'features/profile/presentation/profile_page.dart';
import 'features/wallet/presentation/wallet_page.dart';

void main() => runApp(const ProviderScope(child: WiretapApp()));
class WiretapApp extends ConsumerWidget { const WiretapApp({super.key}); @override Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(title: 'The Wiretap', debugShowCheckedModeBanner: false, theme: appTheme(), routerConfig: _router); }
class AuthGate extends ConsumerWidget { const AuthGate({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final state = ref.watch(authProvider); if (state.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator())); if (state.hasError) return Scaffold(body: AppStateView(message: 'تعذر استعادة الجلسة', onRetry: () => ref.invalidate(authProvider))); return state.value == null ? const LoginPage() : const HomePage(); } }
final _router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const AuthGate()), GoRoute(path: '/reset-password', builder: (_, state) => ResetPasswordPage(token: state.uri.queryParameters['token'])), GoRoute(path: '/game', builder: (_, state) => GamePage(initial: state.extra! as Game)), GoRoute(path: '/wallet', builder: (_, __) => const WalletPage()), GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()), GoRoute(path: '/history', builder: (_, __) => const HistoryPage()), GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()), GoRoute(path: '/admin', builder: (_, __) => const AdminPage()), GoRoute(path: '/help', builder: (_, __) => const InformationPage(title: 'المساعدة', icon: Icons.help_outline, body: 'اختار واحد من الثلاث اختيارات قبل ما الوقت يخلص. السيرفر يسجل القرار والنتيجة. لو خرجت من المهمة تقدر ترجع لها من استكمل لعبة متوقفة، ولو تركتها نهائياً مش هتتكرر.'), GoRoute(path: '/support', builder: (_, __) => const InformationPage(title: 'تواصل مع الدعم', icon: Icons.support_agent, body: 'اكتب للدعم من قناة التشغيل التي وفرها مدير النظام، وأرفق بريد حسابك ومعرّف العملية أو اللعبة. لا ترسل كلمة السر أو رموز الدخول لأي شخص.'))]);
