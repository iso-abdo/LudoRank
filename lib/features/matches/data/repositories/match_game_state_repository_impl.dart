import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state_json_codec.dart';
import 'package:ludo_rank/features/matches/data/data_sources/local/match_dao.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_game_state_repository.dart';

class MatchGameStateRepositoryImpl
    implements MatchGameStateRepository {
  final MatchDao _matchDao;

  MatchGameStateRepositoryImpl(this._matchDao);

  @override
  Future<void> saveGameState({
    required String matchId,
    required LudoGameState state,
  }) async {
    final json = LudoGameStateJsonCodec.encode(state);

    final updatedRows = await _matchDao.saveGameStateJson(
      matchId: matchId,
      gameStateJson: json,
    );

    if (updatedRows == 0) {
      throw StateError(
        'لا يمكن حفظ حالة اللعبة: المباراة غير موجودة ($matchId).',
      );
    }
  }

  @override
  Future<LudoGameState?> loadGameState(String matchId) async {
    final json = await _matchDao.getGameStateJson(matchId);

    if (json == null) {
      return null;
    }

    return LudoGameStateJsonCodec.decode(json);
  }

  @override
  Future<void> clearGameState(String matchId) async {
    final updatedRows = await _matchDao.clearGameStateJson(matchId);

    if (updatedRows == 0) {
      throw StateError(
        'لا يمكن مسح حالة اللعبة: المباراة غير موجودة ($matchId).',
      );
    }
  }
}