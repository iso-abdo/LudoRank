import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/core/database/tables/players_table.dart';

part 'player_dao.g.dart';
@DriftAccessor(tables: [
  Players,
  ],
)
class PlayerDao extends DatabaseAccessor<AppDatabase>
    with _$PlayerDaoMixin {

  PlayerDao(super.db);


  Future<List<Player>> getAllPlayers() {
    return select(players).get();
  }


  Future<Player?> getPlayerById(String id) {
    return (select(players)
      ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }


  Future<void> insertPlayer(
      PlayersCompanion player,
      ) {
    return into(players).insert(player);
  }


  Future<bool> updatePlayer(
      PlayersCompanion player,
      ) {
    return update(players).replace(player);
  }


  Future<int> deletePlayer(String id) {
    return (delete(players)
      ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}