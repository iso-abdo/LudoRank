import '../repositories/tournament_player_repository.dart';

class DeleteTournamentPlayer {
  final TournamentPlayerRepository repository;

  DeleteTournamentPlayer(this.repository);

  Future<void> call(String id) {
    return repository.removePlayer(id);
  }
}