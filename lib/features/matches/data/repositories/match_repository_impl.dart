/*import 'package:ludo_rank/features/matches/data/data_sources/local/match_dao.dart';
import 'package:ludo_rank/features/matches/data/models/match_model.dart';
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchDao dao;

  MatchRepositoryImpl(this.dao);

  @override
  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    final rows = await dao.getTournamentMatches(tournamentId);
    return rows.map(MatchModel.fromDrift).toList();
  }

  @override
  Future<void> addMatch(Match match) {
    return dao.insertMatch(
      MatchModel.fromEntity(match).toCompanion(),
    );
  }

  @override
  Future<void> addMatches(List<Match> matches) {
    return dao.insertMatches(
      matches
          .map(
            (e) => MatchModel.fromEntity(e).toCompanion(),
          )
          .toList(),
    );
  }

  @override
  Future<void> updateMatch(Match match) async {
    final model = MatchModel.fromEntity(match);
    await dao.updateMatch(model.toCompanion());
  }

  @override
  Future<void> deleteMatch(String id) async {
    await dao.deleteMatch(id);
  }
}
*/