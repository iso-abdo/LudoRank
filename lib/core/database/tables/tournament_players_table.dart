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

  List<Index> get indexes => [
    Index(
      'idx_tournament_players_tournament',
      '''
    CREATE INDEX idx_tournament_players_tournament
    ON tournament_players (tournament_id)
    ''',
    ),

    Index(
      'idx_tournament_players_player',
      '''
    CREATE INDEX idx_tournament_players_player
    ON tournament_players (player_id)
    ''',
    ),

    Index(
      'ux_tournament_players_tournament_player',
      '''
    CREATE UNIQUE INDEX ux_tournament_players_tournament_player
    ON tournament_players (tournament_id, player_id)
    ''',
    ),
  ];
}