import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../config/runtime_config.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user.dart';
import '../../features/game/data/game_repository.dart';
import '../../features/wallet/data/wallet_repository.dart';

final tokenStoreProvider = Provider((_) => TokenStore(const FlutterSecureStorage()));
final apiProvider = Provider((ref) => ApiClient(ref.read(tokenStoreProvider)));
final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(apiProvider), ref.read(tokenStoreProvider)));
final gameRepositoryProvider = Provider((ref) => GameRepository(ref.read(apiProvider)));
final walletRepositoryProvider = Provider((ref) => WalletRepository(ref.read(apiProvider)));
final runtimeConfigProvider = FutureProvider<RuntimeConfig>((ref) async => RuntimeConfig.fromJson(await ref.read(apiProvider).get('/config/public-config')));
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override Future<User?> build() => ref.read(authRepositoryProvider).restore();
  Future<void> login(String email, String password) async { state = const AsyncLoading(); state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(email, password)); }
  Future<void> register(String name, String email, String password) async { state = const AsyncLoading(); state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).register(name, email, password)); }
  Future<void> logout() async { await ref.read(authRepositoryProvider).logout(); state = const AsyncData(null); }
  Future<void> refreshUser() async { state = await AsyncValue.guard(() async => User.fromJson(await ref.read(apiProvider).get('/auth/me'))); }
}
