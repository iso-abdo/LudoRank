import '../repositories/tournament_repository.dart';

class DeleteTournament {
  final TournamentRepository repository;

  DeleteTournament(this.repository);

  Future<void> call(String id) {
    return repository.deleteTournament(id);
  }
}