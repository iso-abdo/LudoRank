import '../entities/match_player.dart';
import '../repositories/match_player_repository.dart';

class UpdateMatchPlayer {
  final MatchPlayerRepository repository;

  UpdateMatchPlayer(this.repository);

  Future<void> call(
      MatchPlayer player,
      ) {
    return repository.updateMatchPlayer(player);  }
}
