// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_player_dao.dart';

// ignore_for_file: type=lint
mixin _$MatchPlayerDaoMixin on DatabaseAccessor<AppDatabase> {
  $MatchPlayersTable get matchPlayers => attachedDatabase.matchPlayers;
  MatchPlayerDaoManager get managers => MatchPlayerDaoManager(this);
}

class MatchPlayerDaoManager {
  final _$MatchPlayerDaoMixin _db;
  MatchPlayerDaoManager(this._db);
  $$MatchPlayersTableTableManager get matchPlayers =>
      $$MatchPlayersTableTableManager(_db.attachedDatabase, _db.matchPlayers);
}
