import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class UpdateTournament {
  final TournamentRepository repository;

  UpdateTournament(this.repository);

  Future<void> call(Tournament tournament) {
    return repository.updateTournament(tournament);
  }
}