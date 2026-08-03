import '../entities/match_player.dart';
import '../repositories/match_player_repository.dart';

class AddMatchPlayer {
  final MatchPlayerRepository repository;

  AddMatchPlayer(this.repository);

  Future<void> call(
      MatchPlayer player,
      ) {
    return repository.addPlayer(player);
  }
}