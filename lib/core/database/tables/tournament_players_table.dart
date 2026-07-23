import 'package:drift/drift.dart';

class TournamentPlayers extends Table {
  TextColumn get id => text()();

  TextColumn get tournamentId => text()();

  TextColumn get playerId => text()();

  DateTimeColumn get joinedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}