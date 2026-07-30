import 'package:ludo_rank/features/tournament_players/data/data_sources/local/tournament_player_dao.dart';
import 'package:ludo_rank/features/tournament_players/data/models/tournament_player_model.dart';
import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';
import 'package:ludo_rank/features/tournament_players/domain/repositories/tournament_player_repository.dart';


class TournamentPlayerRepositoryImpl
    implements TournamentPlayerRepository {
  final TournamentPlayerDao dao;

  TournamentPlayerRepositoryImpl(this.dao);

  @override
  Future<List<TournamentPlayer>> getTournamentPlayers(
      String tournamentId,
      ) async {
    final rows = await dao.getTournamentPlayers(
      tournamentId,
    );

    return rows
        .map(
      TournamentPlayerModel.fromDrift,
    )
        .toList();
  }

  @override
  Future<void> addPlayer(
      TournamentPlayer player,
      ) {
    return dao.insertTournamentPlayer(
      TournamentPlayerModel
          .fromEntity(player)
          .toCompanion(),
    );
  }

  @override
  Future<void> removePlayer(
      String id,
      ) {
    return dao.removePlayer(id);
  }

  @override
  Future<void> removeTournamentPlayers(
      String tournamentId,
      ) {
    return dao.removeTournamentPlayers(
      tournamentId,
    );
  }

  @override
  Future<void> updatePlayer(TournamentPlayer player) {
    // TODO: implement updatePlayer
    throw UnimplementedError();
  }
}