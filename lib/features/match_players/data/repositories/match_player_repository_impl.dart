/*import 'package:ludo_rank/features/match_players/data/data_sources/local/match_player_dao.dart';
import 'package:ludo_rank/features/match_players/data/models/match_player_model.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

class MatchPlayerRepositoryImpl implements MatchPlayerRepository {
  final MatchPlayerDao dao;

  MatchPlayerRepositoryImpl(this.dao);

  @override
  Future<List<MatchPlayer>> getMatchPlayers(
      String matchId,
      ) async {
    final rows = await dao.getMatchPlayers(matchId);

    return rows
        .map(MatchPlayerModel.fromDrift)
        .toList();
  }

  @override
  Future<void> addPlayer(
      MatchPlayer player,
      ) {
    return dao.insertPlayer(
      MatchPlayerModel.fromEntity(player).toCompanion(),
    );
  }

  @override
  Future<void> addPlayers(
      List<MatchPlayer> players,
      ) async {
    for (final player in players) {
      await addPlayer(player);
    }
  }

  @override
  Future<void> removePlayer(
      String id,
      ) {
    return dao.removePlayer(id);
  }

  @override
  Future<void> removeMatchPlayers(
      String matchId,
      ) {
    return dao.removeMatchPlayers(matchId);
  }
}*/