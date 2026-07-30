import '../entities/tournament_player.dart';
import '../repositories/tournament_player_repository.dart';

class GetTournamentPlayers {
  final TournamentPlayerRepository repository;

  GetTournamentPlayers(this.repository);

  Future<List<TournamentPlayer>> call(String tournamentId) {
    return repository.getTournamentPlayers(tournamentId);
  }
}