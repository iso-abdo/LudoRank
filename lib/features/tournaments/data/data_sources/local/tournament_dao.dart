import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/tournaments_table.dart';

part 'tournament_dao.g.dart';

@DriftAccessor(
  tables: [
    Tournaments,
  ],
)
class TournamentDao extends DatabaseAccessor<AppDatabase>
    with _$TournamentDaoMixin {

  TournamentDao(super.db);

  /// جميع البطولات
  Future<List<Tournament>> getAllTournaments() {
    return select(tournaments).get();
  }

  /// بطولة واحدة
  Future<Tournament?> getTournamentById(
      String id,
      ) {
    return (select(tournaments)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .getSingleOrNull();
  }

  /// إضافة بطولة
  Future<void> insertTournament(
      TournamentsCompanion tournament,
      ) {
    return into(tournaments).insert(tournament);
  }

  /// تعديل بطولة
  Future<bool> updateTournament(
      TournamentsCompanion tournament,
      ) {
    return update(tournaments).replace(tournament);
  }

  /// حذف بطولة
  Future<int> deleteTournament(
      String id,
      ) {
    return (delete(tournaments)
      ..where(
            (tbl) => tbl.id.equals(id),
      ))
        .go();
  }
}