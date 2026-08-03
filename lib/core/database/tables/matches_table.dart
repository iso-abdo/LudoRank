import 'package:drift/drift.dart';

import 'tournaments_table.dart';

@DataClassName('MatchData')
class Matches extends Table {
  /// Match ID (UUID)
  TextColumn get id => text()();

  /// Tournament ID
  TextColumn get tournamentId =>
      text().references(Tournaments, #id)();

  /// Match number داخل البطولة
  IntColumn get matchNumber => integer()();

  /// pending
  /// playing
  /// finished
  /// cancelled
  TextColumn get status => text()();

  /// Created At
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Updated At
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
  // داخل كلاس Matches
  List<Index> get indexes => [
    Index('idx_matches_tournament',
        'CREATE INDEX idx_matches_tournament ON matches (tournament_id)'),
  ];
}