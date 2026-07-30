import '../entities/player.dart';
import '../repositories/player_repository.dart';

class UpdatePlayer {
  final PlayerRepository repository;

  UpdatePlayer(this.repository);

  Future<void> call(Player player) {
    return repository.updatePlayer(player);
  }
}