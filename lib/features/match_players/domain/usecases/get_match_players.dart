import '../entities/match_player.dart';
import '../repositories/match_player_repository.dart';

class GetMatchPlayers {
  final MatchPlayerRepository repository;

  GetMatchPlayers(this.repository);

  Future<List<MatchPlayer>> call(
      String matchId,
      ) {
    return repository.getMatchPlayers(matchId);
  }
}