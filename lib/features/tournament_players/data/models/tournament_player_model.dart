import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart' as db;
import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';

class TournamentPlayerModel extends TournamentPlayer {
  const TournamentPlayerModel({
    required super.id,
    required super.tournamentId,
    required super.playerId,
    required super.joinedAt,
  });

  factory TournamentPlayerModel.fromDrift(
      db.TournamentPlayer row,
      ) {
    return TournamentPlayerModel(
      id: row.id,
      tournamentId: row.tournamentId,
      playerId: row.playerId,
      joinedAt: row.joinedAt,
    );
  }

  factory TournamentPlayerModel.fromEntity(
      TournamentPlayer entity,
      ) {
    return TournamentPlayerModel(
      id: entity.id,
      tournamentId: entity.tournamentId,
      playerId: entity.playerId,
      joinedAt: entity.joinedAt,
    );
  }

  db.TournamentPlayersCompanion toCompanion() {
    return db.TournamentPlayersCompanion(
      id: Value(id),
      tournamentId: Value(tournamentId),
      playerId: Value(playerId),
      joinedAt: Value(joinedAt),
    );
  }
}