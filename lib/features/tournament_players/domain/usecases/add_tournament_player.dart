import '../entities/tournament_player.dart';
import '../repositories/tournament_player_repository.dart';

class AddTournamentPlayer {
  final TournamentPlayerRepository repository;

  AddTournamentPlayer(this.repository);

  Future<void> call(TournamentPlayer player) {
    return repository.addPlayer(player);
  }
}