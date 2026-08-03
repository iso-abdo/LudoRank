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

  /// جميع لاعبى المباراة
  Future<List<MatchPlayer>> getMatchPlayers(
      String matchId,
      ) {
    return (select(matchPlayers)
      ..where(
            (tbl) => tbl.matchId.equals(matchId),
      )
      ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.seat),
      ]))
        .get();
  }

  /// لاعب واحد داخل المباراة
  Future<MatchPlayer?> getMatchPlayer(
      String id,
      ) {
    return (select(matchPlayers)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .getSingleOrNull();
  }

  /// إضافة لاعب للمباراة
  Future<void> insertMatchPlayer(
      MatchPlayersCompanion player,
      ) {
    return into(matchPlayers).insert(player);
  }

  /// تحديث بيانات اللاعب داخل المباراة
  Future<bool> updateMatchPlayer(
      MatchPlayersCompanion player,
      ) {
    return update(matchPlayers).replace(player);
  }

  /// حذف لاعب
  Future<int> removePlayer(
      String id,
      ) {
    return (delete(matchPlayers)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .go();
  }

  /// حذف جميع لاعبى المباراة
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