import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/matches_table.dart';
import 'package:ludo_rank/core/database/tables/players_table.dart';
import 'package:ludo_rank/core/database/tables/tournaments_table.dart';

part 'home_dao.g.dart';

@DriftAccessor(
  tables: [
    Players,
    Tournaments,
    Matches,
  ],
)
class HomeDao extends DatabaseAccessor<AppDatabase>
    with _$HomeDaoMixin {

  HomeDao(super.db);

  Future<int> getPlayersCount() async {
    final query = selectOnly(players)
      ..addColumns([
        players.id.count(),
      ]);

    final row = await query.getSingle();

    return row.read(players.id.count()) ?? 0;
  }

  Future<int> getTournamentsCount() async {
    final query = selectOnly(tournaments)
      ..addColumns([
        tournaments.id.count(),
      ]);

    final row = await query.getSingle();

    return row.read(tournaments.id.count()) ?? 0;
  }

  Future<int> getMatchesCount() async {
    final query = selectOnly(matches)
      ..addColumns([
        matches.id.count(),
      ]);

    final row = await query.getSingle();

    return row.read(matches.id.count()) ?? 0;
  }

  Future<int> getFinishedTournamentsCount() async {
    final query = selectOnly(tournaments)
      ..addColumns([
        tournaments.id.count(),
      ])
      ..where(
        tournaments.status.equals('finished'),
      );

    final row = await query.getSingle();

    return row.read(tournaments.id.count()) ?? 0;
  }
}