import '../entities/player.dart';
import '../repositories/player_repository.dart';

class GetPlayer {
  final PlayerRepository repository;

  GetPlayer(this.repository);

  Future<Player?> call(String id) {
    return repository.getPlayerById(id);
  }
}