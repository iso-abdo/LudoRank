import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class GetTournament {
  final TournamentRepository repository;

  GetTournament(this.repository);

  Future<Tournament?> call(String id) {
    return repository.getTournamentById(id);
  }
}