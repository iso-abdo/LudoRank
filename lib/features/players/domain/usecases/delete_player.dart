import '../repositories/player_repository.dart';

class DeletePlayer {
  final PlayerRepository repository;

  DeletePlayer(this.repository);

  Future<void> call(String id) {
    return repository.deletePlayer(id);
  }
}