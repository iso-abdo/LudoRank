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

  Future<List<Tournament>> getAllTournaments() {
    return select(tournaments).get();
  }

  Future<Tournament?> getTournamentById(String id) {
    return (select(tournaments)
      ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertTournament(
      TournamentsCompanion tournament,
      ) {
    return into(tournaments).insert(tournament);
  }

}