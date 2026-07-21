import '../../../core/api/api_client.dart';
import '../domain/game.dart';
class GameRepository { GameRepository(this._api); final ApiClient _api; Future<Game> start(int stake) async => Game.fromJson(await _api.post('/games', data: {'stake': stake})); Future<Game> resume() async => Game.fromJson(await _api.get('/games/resume')); Future<Game> get(String id) async => Game.fromJson(await _api.get('/games/$id')); Future<Game> choose(String id, int choice) async => Game.fromJson(await _api.post('/games/$id/choice', data: {'choiceNumber': choice})); Future<void> abandon(String id) => _api.post('/games/$id/abandon').then((_) {}); }

