// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_dao.dart';

// ignore_for_file: type=lint
mixin _$MatchDaoMixin on DatabaseAccessor<AppDatabase> {
  $TournamentsTable get tournaments => attachedDatabase.tournaments;
  $MatchesTable get matches => attachedDatabase.matches;
  MatchDaoManager get managers => MatchDaoManager(this);
}

class MatchDaoManager {
  final _$MatchDaoMixin _db;
  MatchDaoManager(this._db);
  $$TournamentsTableTableManager get tournaments =>
      $$TournamentsTableTableManager(_db.attachedDatabase, _db.tournaments);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db.attachedDatabase, _db.matches);
}
