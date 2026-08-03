import '../entities/match_player.dart';
import '../repositories/match_player_repository.dart';

class AddMatchPlayers {
  final MatchPlayerRepository repository;

  AddMatchPlayers(this.repository);

  Future<void> call(
      List<MatchPlayer> players,
      ) {
    return repository.addPlayers(players);
  }
}