// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_player_dao.dart';

// ignore_for_file: type=lint
mixin _$TournamentPlayerDaoMixin on DatabaseAccessor<AppDatabase> {
  $TournamentPlayersTable get tournamentPlayers =>
      attachedDatabase.tournamentPlayers;
  TournamentPlayerDaoManager get managers => TournamentPlayerDaoManager(this);
}

class TournamentPlayerDaoManager {
  final _$TournamentPlayerDaoMixin _db;
  TournamentPlayerDaoManager(this._db);
  $$TournamentPlayersTableTableManager get tournamentPlayers =>
      $$TournamentPlayersTableTableManager(
        _db.attachedDatabase,
        _db.tournamentPlayers,
      );
}
