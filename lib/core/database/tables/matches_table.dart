import 'package:drift/drift.dart';

@DataClassName('MatchData')
class Matches extends Table {
  TextColumn get id => text()();

  TextColumn get tournamentId => text()();

  IntColumn get round => integer()();

  TextColumn get status => text()();

  TextColumn get winnerId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
