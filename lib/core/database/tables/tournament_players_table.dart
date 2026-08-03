import 'package:drift/drift.dart';
import 'package:ludo_rank/core/database/tables/players_table.dart';
import 'package:ludo_rank/core/database/tables/tournaments_table.dart';

class TournamentPlayers extends Table {
  TextColumn get id => text()();

  TextColumn get tournamentId =>
      text().references(Tournaments, #id)();

  TextColumn get playerId =>
      text().references(Players, #id)();

  DateTimeColumn get joinedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  // إضافة الفهارس لتحسين أداء البحث والـ Joins
  List<Index> get indexes => [
    Index('idx_tournament_players_tournament',
        'CREATE INDEX idx_tournament_players_tournament ON tournament_players (tournament_id)'),
    Index('idx_tournament_players_player',
        'CREATE INDEX idx_tournament_players_player ON tournament_players (player_id)'),
  ];
}