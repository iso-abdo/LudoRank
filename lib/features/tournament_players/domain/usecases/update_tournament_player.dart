import '../entities/tournament_player.dart';
import '../repositories/tournament_player_repository.dart';

class UpdateTournamentPlayer {
  final TournamentPlayerRepository repository;

  UpdateTournamentPlayer(this.repository);

  Future<void> call(TournamentPlayer player) {
    return repository.updatePlayer(player);
  }
}