import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/matches_table.dart';

part 'match_dao.g.dart';

@DriftAccessor(tables: [Matches])
class MatchDao extends DatabaseAccessor<AppDatabase>
    with _$MatchDaoMixin {

  MatchDao(super.db);

  /// جميع مباريات بطولة
  Future<List<MatchData>> getTournamentMatches(String tournamentId) {
    return (select(matches)
      ..where((tbl) => tbl.tournamentId.equals(tournamentId))
      ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.matchNumber),
      ]))
        .get();
  }

  /// مباراة واحدة
  Future<MatchData?> getMatchById(String id) {
    return (select(matches)
      ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// إنشاء مباراة
  Future<void> insertMatch(MatchesCompanion companion) {
    return into(matches).insert(companion);
  }

  /// تعديل مباراة
  Future<bool> updateMatch(MatchesCompanion companion) {
    return update(matches).replace(companion);
  }

  /// حذف مباراة
  Future<int> deleteMatch(String id) {
    return (delete(matches)
      ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}