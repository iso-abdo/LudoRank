import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart' as db;
import 'package:ludo_rank/features/matches/domain/entities/match.dart';



class MatchModel extends Match {
  const MatchModel({
    required super.id,
    required super.tournamentId,
    required super.round,
    required super.status,
    super.winnerId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MatchModel.fromDrift(db.MatchData  row) {
    return MatchModel(
      id: row.id,
      tournamentId: row.tournamentId,
      round: row.round,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == row.status,
      ),
      winnerId: row.winnerId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory MatchModel.fromEntity(Match entity) {
    return MatchModel(
      id: entity.id,
      tournamentId: entity.tournamentId,
      round: entity.round,
      status: entity.status,
      winnerId: entity.winnerId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  db.MatchesCompanion toCompanion() {
    return db.MatchesCompanion(
      id: Value(id),
      tournamentId: Value(tournamentId),
      round: Value(round),
      status: Value(status.name),
      winnerId: Value(winnerId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
