import 'package:drift/drift.dart';
import 'package:ludo_rank/core/database/tables/matches_table.dart';
import 'package:ludo_rank/core/database/tables/players_table.dart';
class MatchPlayers extends Table {
  TextColumn get id => text()();

  TextColumn get matchId => text().references(Matches, #id)();

  TextColumn get playerId => text().references(Players, #id)();

  /// ترتيب اللاعب داخل المباراة
  IntColumn get seat => integer()();

  /// ترتيبه بعد انتهاء المباراة
  IntColumn get rank => integer().nullable()();

  /// النقاط التى حصل عليها
  IntColumn get points => integer().withDefault(const Constant(0))();

  /// هل اللاعب أنهى المباراة؟
  BoolColumn get finished =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
// /داخل كلاس MatchPlayers
  List<Index> get indexes => [
    Index('idx_match_players_match',
        'CREATE INDEX idx_match_players_match ON match_players (match_id)'),
    Index('idx_match_players_player',
        'CREATE INDEX idx_match_players_player ON match_players (player_id)'),
  ];
}