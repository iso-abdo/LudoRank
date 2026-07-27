import 'package:ludo_rank/features/matches/domain/entities/match.dart';

abstract class MatchRepository {
  Future<List<Match>> getTournamentMatches(String tournamentId);

  Future<void> addMatch(Match match);

  Future<void> addMatches(List<Match> matches);

  Future<void> updateMatch(Match match);

  Future<void> deleteMatch(String id);
}