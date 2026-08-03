import '../repositories/match_player_repository.dart';

class DeleteMatchPlayer {
  final MatchPlayerRepository repository;

  DeleteMatchPlayer(this.repository);

  Future<void> call(String id) {
    return repository.removePlayer(id);
  }
}