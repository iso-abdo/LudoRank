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

  /// جميع لاعبى البطولة
  Future<List<TournamentPlayer>> getTournamentPlayers(
      String tournamentId,
      ) {
    return (select(tournamentPlayers)
      ..where(
            (tbl) => tbl.tournamentId.equals(tournamentId),
      ))
        .get();
  }

  /// لاعب واحد داخل البطولة
  Future<TournamentPlayer?> getTournamentPlayer(
      String id,
      ) {
    return (select(tournamentPlayers)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .getSingleOrNull();
  }

  /// إضافة لاعب للبطولة
  Future<void> insertTournamentPlayer(
      TournamentPlayersCompanion player,
      ) {
    return into(tournamentPlayers).insert(player);
  }

  /// تحديث بيانات لاعب البطولة
  Future<bool> updateTournamentPlayer(
      TournamentPlayersCompanion player,
      ) {
    return update(tournamentPlayers).replace(player);
  }

  /// حذف لاعب من البطولة
  Future<int> removePlayer(
      String id,
      ) {
    return (delete(tournamentPlayers)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .go();
  }

  /// حذف جميع لاعبى البطولة
  Future<int> removeTournamentPlayers(
      String tournamentId,
      ) {
    return (delete(tournamentPlayers)
      ..where(
            (tbl) => tbl.tournamentId.equals(tournamentId),
      ))
        .go();
  }
}