import '../repositories/match_player_repository.dart';

class RemoveMatchPlayer {
  final MatchPlayerRepository repository;

  RemoveMatchPlayer(this.repository);

  Future<void> call(
      String id,
      ) {
    return repository.removePlayer(id);
  }
}