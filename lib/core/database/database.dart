import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/players/data/data_sources/local/player_dao.dart';
import 'tables/players_table.dart';
import 'tables/tournaments_table.dart';
part 'database.g.dart';

@DriftDatabase(
  tables: [
    Players,
    Tournaments,
  ],
  daos: [
    PlayerDao,
  ],
)
class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());


  @override
  int get schemaVersion => 1;

}


LazyDatabase _openConnection() {

  return LazyDatabase(() async {

    final dir =
    await getApplicationDocumentsDirectory();


    final file = File(
      p.join(
        dir.path,
        'ludorank.db',
      ),
    );


    return NativeDatabase(file);

  });
}