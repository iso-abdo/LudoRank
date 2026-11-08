import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import 'package:ludo_rank/core/database/tables/match_players_table.dart';
import 'package:ludo_rank/core/database/tables/matches_table.dart';
import 'package:ludo_rank/core/database/tables/players_table.dart';
import 'package:ludo_rank/core/database/tables/tournament_players_table.dart';
import 'package:ludo_rank/core/database/tables/tournaments_table.dart';

import 'package:ludo_rank/features/match_players/data/data_sources/local/match_player_dao.dart';
import 'package:ludo_rank/features/matches/data/data_sources/local/match_dao.dart';
import 'package:ludo_rank/features/players/data/data_sources/local/player_dao.dart';
import 'package:ludo_rank/features/tournament_players/data/data_sources/local/tournament_player_dao.dart';
import 'package:ludo_rank/features/tournaments/data/data_sources/local/tournament_dao.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Players, Tournaments, TournamentPlayers, Matches, MatchPlayers],
  daos: [
    PlayerDao,
    TournamentDao,
    TournamentPlayerDao,
    MatchDao,
    MatchPlayerDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor used by database migration tests.
  AppDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    onUpgrade: (Migrator m, int from, int to) async {
      // Migration 1 -> 2:
      // Add playersCount and populate it from MatchPlayers.
      if (from < 2) {
        await m.addColumn(matches, matches.playersCount);

        await customStatement('''
          UPDATE matches
          SET players_count = (
            SELECT COUNT(*)
            FROM match_players
            WHERE match_players.match_id = matches.id
          )
        ''');
      }

      // Migration 2 -> 3:
      // Add nullable JSON snapshot for the Ludo game state.
      if (from < 3) {
        await m.addColumn(matches, matches.gameStateJson);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();

    debugPrint('Database Path = ${dir.path}');

    final file = File(p.join(dir.path, 'ludorank.db'));

    debugPrint(file.path);

    return NativeDatabase(file);
  });
}
