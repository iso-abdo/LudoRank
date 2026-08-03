import '../entities/match.dart';
import '../repositories/match_repository.dart';

class GetAllMatches {
  final MatchRepository repository;

  GetAllMatches(this.repository);

  Future<List<Match>> call(String tournamentId) {
    return repository.getTournamentMatches(tournamentId);
  }
}