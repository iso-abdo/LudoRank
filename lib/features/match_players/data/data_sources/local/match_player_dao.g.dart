// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_player_dao.dart';

// ignore_for_file: type=lint
mixin _$MatchPlayerDaoMixin on DatabaseAccessor<AppDatabase> {
  $TournamentsTable get tournaments => attachedDatabase.tournaments;
  $MatchesTable get matches => attachedDatabase.matches;
  $PlayersTable get players => attachedDatabase.players;
  $MatchPlayersTable get matchPlayers => attachedDatabase.matchPlayers;
  MatchPlayerDaoManager get managers => MatchPlayerDaoManager(this);
}

class MatchPlayerDaoManager {
  final _$MatchPlayerDaoMixin _db;
  MatchPlayerDaoManager(this._db);
  $$TournamentsTableTableManager get tournaments =>
      $$TournamentsTableTableManager(_db.attachedDatabase, _db.tournaments);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db.attachedDatabase, _db.matches);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$MatchPlayersTableTableManager get matchPlayers =>
      $$MatchPlayersTableTableManager(_db.attachedDatabase, _db.matchPlayers);
}
