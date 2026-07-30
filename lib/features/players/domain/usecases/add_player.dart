import '../entities/player.dart';
import '../repositories/player_repository.dart';

class AddPlayer {
  final PlayerRepository repository;

  AddPlayer(this.repository);

  Future<void> call(Player player) {
    return repository.addPlayer(player);
  }
}