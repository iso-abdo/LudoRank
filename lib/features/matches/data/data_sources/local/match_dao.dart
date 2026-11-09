import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/database.dart' as db;
import 'package:ludo_rank/core/database/tables/matches_table.dart';

part 'match_dao.g.dart';

@DriftAccessor(tables: [Matches])
class MatchDao extends DatabaseAccessor<AppDatabase> with _$MatchDaoMixin {
  MatchDao(super.db);

  Future<MatchData?> getMatchById(String id) {
    return (select(
      matches,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertMatch(MatchesCompanion match) {
    return into(matches).insert(match);
  }

  Future<void> insertMatches(List<MatchesCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(matches, companions);
    });
  }

  Future<bool> updateMatch(MatchesCompanion match) async {
    if (!match.id.present) {
      throw ArgumentError(
        'Match ID is required to update a match.',
      );
    }

    final updatedRows = await (update(matches)
      ..where((tbl) => tbl.id.equals(match.id.value)))
        .write(match);

    return updatedRows > 0;
  }
  Future<int> deleteMatch(String id) {
    return (delete(matches)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<db.MatchData>> getTournamentMatches(String tournamentId) {
    return (select(
      matches,
    )..where((tbl) => tbl.tournamentId.equals(tournamentId))).get();
  }

  Future<List<db.MatchData>> getAllMatches() {
    return select(matches).get();
  }
  /// حفظ JSON الخاص بحالة اللعبة دون تعديل بيانات المباراة الأخرى.
  ///
  /// يرجع عدد الصفوف التي تم تحديثها:
  /// 1 إذا كانت المباراة موجودة، و0 إذا لم تكن موجودة.
  Future<int> saveGameStateJson({
    required String matchId,
    required String gameStateJson,
  }) {
    return (update(matches)
      ..where((tbl) => tbl.id.equals(matchId)))
        .write(
      MatchesCompanion(
        gameStateJson: Value(gameStateJson),
      ),
    );
  }

  /// قراءة JSON الخاص بحالة اللعبة.
  ///
  /// يرجع null إذا لم توجد حالة محفوظة أو لم توجد المباراة.
  Future<String?> getGameStateJson(String matchId) async {
    final match = await getMatchById(matchId);
    return match?.gameStateJson;
  }

  /// مسح الحالة المحفوظة فقط، مع الاحتفاظ بسجل المباراة.
  ///
  /// يرجع عدد الصفوف التي تم تحديثها.
  Future<int> clearGameStateJson(String matchId) {
    return (update(matches)
      ..where((tbl) => tbl.id.equals(matchId)))
        .write(
      const MatchesCompanion(
        gameStateJson: Value(null),
      ),
    );
  }
}
