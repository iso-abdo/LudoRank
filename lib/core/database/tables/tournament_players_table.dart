import 'package:drift/drift.dart';
import 'package:ludo_rank/core/database/tables/players_table.dart';
import 'package:ludo_rank/core/database/tables/tournaments_table.dart';

class TournamentPlayers extends Table {
  TextColumn get id => text()();

  TextColumn get tournamentId =>
      text().references(Tournaments, #id)();

  TextColumn get playerId => text().references(Players, #id)();

  DateTimeColumn get joinedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}