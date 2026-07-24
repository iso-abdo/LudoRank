import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/match_players_table.dart';

part 'match_player_dao.g.dart';

@DriftAccessor(
  tables: [
    MatchPlayers,
  ],
)
class MatchPlayerDao extends DatabaseAccessor<AppDatabase>
    with _$MatchPlayerDaoMixin {
  MatchPlayerDao(super.db);

  Future<List<MatchPlayer>> getMatchPlayers(
      String matchId,
      ) {
    return (select(matchPlayers)
      ..where(
            (tbl) => tbl.matchId.equals(matchId),
      ))
        .get();
  }

  Future<void> insertPlayer(
      MatchPlayersCompanion player,
      ) {
    return into(matchPlayers).insert(player);
  }

  Future<int> removePlayer(
      String id,
      ) {
    return (delete(matchPlayers)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .go();
  }

  Future<int> removeMatchPlayers(
      String matchId,
      ) {
    return (delete(matchPlayers)
      ..where(
            (tbl) => tbl.matchId.equals(matchId),
      ))
        .go();
  }
}