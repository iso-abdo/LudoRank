
import 'package:ludo_rank/features/tournaments/data/data_sources/local/tournament_dao.dart';
import 'package:ludo_rank/features/tournaments/data/models/tournament_model.dart';

import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';
import 'package:ludo_rank/features/tournaments/domain/repositories/tournament_repository.dart';

class TournamentRepositoryImpl implements TournamentRepository {

  final TournamentDao dao;

  TournamentRepositoryImpl(this.dao);

  @override
  Future<List<Tournament>> getAllTournaments() async {

    final rows = await dao.getAllTournaments();

    return rows
        .map(TournamentModel.fromDrift)
        .toList();

  }

  @override
  Future<Tournament?> getTournamentById(
      String id,
      ) async {

    final row = await dao.getTournamentById(id);

    if (row == null) {
      return null;
    }

    return TournamentModel.fromDrift(row);

  }

  @override
  Future<void> addTournament(
      Tournament tournament,
      ) async {

    final model = TournamentModel.fromEntity(
      tournament,
    );

    await dao.insertTournament(
      model.toCompanion(),
    );

  }

}