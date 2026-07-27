import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart' as db;
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

class MatchPlayerModel extends MatchPlayer {
  const MatchPlayerModel({
    required super.id,
    required super.matchId,
    required super.playerId,
    required super.seat,
    required super.rank,
    required super.points,
    required super.finished,
  });

  factory MatchPlayerModel.fromDrift(db.MatchPlayer row) {
    return MatchPlayerModel(
      id: row.id,
      matchId: row.matchId,
      playerId: row.playerId,
      seat: row.seat,
      rank: row.rank,
      points: row.points,
      finished: row.finished,
    );
  }

  factory MatchPlayerModel.fromEntity(MatchPlayer entity) {
    return MatchPlayerModel(
      id: entity.id,
      matchId: entity.matchId,
      playerId: entity.playerId,
      seat: entity.seat,
      rank: entity.rank,
      points: entity.points,
      finished: entity.finished,
    );
  }

  db.MatchPlayersCompanion toCompanion() {
    return db.MatchPlayersCompanion(
      id: Value(id),
      matchId: Value(matchId),
      playerId: Value(playerId),
      seat: Value(seat),
      rank: Value(rank),
      points: Value(points),
      finished: Value(finished),
    );
  }
}