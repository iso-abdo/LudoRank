import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart' as db;
import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';
class TournamentModel extends Tournament {
  const TournamentModel({
    required super.id,
    required super.name,
    required super.status,
    required super.rounds,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TournamentModel.fromDrift(db.Tournament row) {
    return TournamentModel(
      id: row.id,
      name: row.name,
      status: TournamentStatus.values.firstWhere(
            (e) => e.name == row.status,
      ),
      rounds: row.rounds,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory TournamentModel.fromEntity(Tournament entity) {
    return TournamentModel(
      id: entity.id,
      name: entity.name,
      status: entity.status,
      rounds: entity.rounds,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }



  db.TournamentsCompanion toCompanion() {
    return db.TournamentsCompanion(
      id: Value(id),
      name: Value(name),
      status: Value(status.name),
      rounds: Value(rounds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }


}