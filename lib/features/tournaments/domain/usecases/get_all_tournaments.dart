import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class GetAllTournaments {
  final TournamentRepository repository;

  GetAllTournaments(this.repository);

  Future<List<Tournament>> call() {
    return repository.getAllTournaments();
  }
}