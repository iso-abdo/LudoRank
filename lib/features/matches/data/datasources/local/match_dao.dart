import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/matches_table.dart';
import 'package:ludo_rank/core/database/database.dart' as db;

part 'match_dao.g.dart';

@DriftAccessor(
  tables: [
    Matches,
  ],
)
class MatchDao extends DatabaseAccessor<AppDatabase>
    with _$MatchDaoMixin {
  MatchDao(super.db);

  Future<List<db.Match>> getTournamentMatches(
      String tournamentId,
      ) {
    return (select(matches)
      ..where((tbl) => tbl.tournamentId.equals(tournamentId)))
        .get();
  }

  Future<void> insertMatch(
      MatchesCompanion match,
      ) {
    return into(matches).insert(match);
  }

  Future<bool> updateMatch(
      MatchesCompanion match,
      ) {
    return update(matches).replace(match);
  }

  Future<int> deleteMatch(
      String id,
      ) {
    return (delete(matches)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .go();
  }
}
