import 'package:ludo_rank/features/matches/data/data_sources/local/match_dao.dart';
import 'package:ludo_rank/features/matches/data/models/match_model.dart';
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchDao dao;

  MatchRepositoryImpl(this.dao);

  @override
  Future<List<Match>> getTournamentMatches(
      String tournamentId,
      ) async {
    final rows = await dao.getTournamentMatches(
      tournamentId,
    );

    return rows
        .map(MatchModel.fromDrift)
        .toList();
  }

  @override
  Future<Match?> getById(
      String id,
      ) async {
    final row = await dao.getMatchById(id);

    if (row == null) {
      return null;
    }

    return MatchModel.fromDrift(row);
  }

  @override
  Future<void> create(
      Match match,
      ) async {
    final model = MatchModel.fromEntity(match);

    await dao.insertMatch(
      model.toCompanion(),
    );
  }

  @override
  Future<void> update(
      Match match,
      ) async {
    final model = MatchModel.fromEntity(match);

    await dao.updateMatch(
      model.toCompanion(),
    );
  }

  @override
  Future<void> delete(
      String id,
      ) async {
    await dao.deleteMatch(id);
  }
}