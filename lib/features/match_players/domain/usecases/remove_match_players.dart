import '../repositories/match_player_repository.dart';

class RemoveMatchPlayers {
  final MatchPlayerRepository repository;

  RemoveMatchPlayers(this.repository);

  Future<void> call(
      String matchId,
      ) {
    return repository.removeMatchPlayers(matchId);
  }
}