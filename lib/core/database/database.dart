import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ludo_rank/core/database/tables/tournament_players_table.dart';
import 'package:ludo_rank/features/tournaments/data/datasources/local/tournament_dao.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/players/data/data_sources/local/player_dao.dart';
import 'tables/players_table.dart';
import 'tables/tournaments_table.dart';
import 'package:flutter/foundation.dart';

import 'tables/matches_table.dart';
import 'tables/match_players_table.dart';

part 'database.g.dart';


@DriftDatabase(
  tables: [
    Players,
    Tournaments,
    TournamentPlayers,
    Matches,
    MatchPlayers,
  ],
  daos: [
    PlayerDao,
    TournamentDao,

  ],
)
class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 1;

}


LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();

    debugPrint("Database Path = ${dir.path}");

    final file = File(
      p.join(dir.path, 'ludorank.db'),
    );

    debugPrint(file.path);

    return NativeDatabase(file);
  });
}