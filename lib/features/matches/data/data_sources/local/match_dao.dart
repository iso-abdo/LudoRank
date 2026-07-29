/*import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart' as db;
import 'package:ludo_rank/core/database/tables/matches_table.dart';

part 'match_dao.g.dart';

@DriftAccessor(tables: [Matches])
class MatchDao extends DatabaseAccessor<db.AppDatabase>
    with _$MatchDaoMixin {

  MatchDao(db.AppDatabase db) : super(db);

  Future<List<db.MatchData>> getTournamentMatches(String tournamentId) {
    return (select(matches)
      ..where((tbl) => tbl.tournamentId.equals(tournamentId)))
        .get();
  }

  Future<void> insertMatch(db.MatchesCompanion match) {
    return into(matches).insert(match);
  }

  Future<void> insertMatches(List<db.MatchesCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(matches, companions);
    });
  }

  Future<bool> updateMatch(db.MatchesCompanion match) {
    return update(matches).replace(match);
  }

  Future<int> deleteMatch(String id) {
    return (delete(matches)..where((tbl) => tbl.id.equals(id))).go();
  }
}*/