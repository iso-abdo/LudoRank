// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_dao.dart';

// ignore_for_file: type=lint
mixin _$HomeDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlayersTable get players => attachedDatabase.players;
  $TournamentsTable get tournaments => attachedDatabase.tournaments;
  $MatchesTable get matches => attachedDatabase.matches;
  HomeDaoManager get managers => HomeDaoManager(this);
}

class HomeDaoManager {
  final _$HomeDaoMixin _db;
  HomeDaoManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$TournamentsTableTableManager get tournaments =>
      $$TournamentsTableTableManager(_db.attachedDatabase, _db.tournaments);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db.attachedDatabase, _db.matches);
}
