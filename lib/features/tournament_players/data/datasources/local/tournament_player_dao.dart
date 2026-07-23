import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/tournament_players_table.dart';

part 'tournament_player_dao.g.dart';

@DriftAccessor(
  tables: [
    TournamentPlayers,
  ],
)
class TournamentPlayerDao extends DatabaseAccessor<AppDatabase>
    with _$TournamentPlayerDaoMixin {
  TournamentPlayerDao(super.db);

  Future<List<TournamentPlayer>> getTournamentPlayers(
      String tournamentId,
      ) {
    return (select(tournamentPlayers)
      ..where((t) => t.tournamentId.equals(tournamentId)))
        .get();
  }

  Future<void> insertPlayer(
      TournamentPlayersCompanion companion,
      ) {
    return into(tournamentPlayers).insert(companion);
  }

  Future<int> removePlayer(
      String id,
      ) {
    return (delete(tournamentPlayers)
      ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> removeTournamentPlayers(
      String tournamentId,
      ) {
    return (delete(tournamentPlayers)
      ..where((t) => t.tournamentId.equals(tournamentId)))
        .go();
  }
}