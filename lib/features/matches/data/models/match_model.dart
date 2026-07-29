import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';

class MatchModel extends Match {
  const MatchModel({
    required super.id,
    required super.tournamentId,
    required super.playersCount,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MatchModel.fromDrift(MatchData row) {
    return MatchModel(
      id: row.id,
      tournamentId: row.tournamentId,
      playersCount: 0, // سيتم حسابها من MatchPlayers
      status: MatchStatus.values.firstWhere(
            (e) => e.name == row.status,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory MatchModel.fromEntity(Match match) {
    return MatchModel(
      id: match.id,
      tournamentId: match.tournamentId,
      playersCount: match.playersCount,
      status: match.status,
      createdAt: match.createdAt,
      updatedAt: match.updatedAt,
    );
  }

  MatchesCompanion toCompanion() {
    return MatchesCompanion(
      id: Value(id),
      tournamentId: Value(tournamentId),
      matchNumber: const Value(0),
      status: Value(status.name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}