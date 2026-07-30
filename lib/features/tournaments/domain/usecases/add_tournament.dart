import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class AddTournament {
  final TournamentRepository repository;

  AddTournament(this.repository);

  Future<void> call(Tournament tournament) {
    return repository.addTournament(tournament);
  }
}