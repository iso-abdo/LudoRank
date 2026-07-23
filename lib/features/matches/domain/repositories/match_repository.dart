import '../entities/match.dart';

abstract class MatchRepository {
  Future<List<Match>> getMatchesByTournament(String tournamentId);
  Future<void> addMatch(Match match);
  Future<void> updateMatch(Match match);
  Future<void> deleteMatch(String id);
}
