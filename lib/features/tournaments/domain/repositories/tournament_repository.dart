import '../entities/tournament.dart';

abstract class TournamentRepository {
  Future<List<Tournament>> getAllTournaments();

  Future<Tournament?> getTournamentById(
      String id,
      );

  Future<void> addTournament(
      Tournament tournament,
      );
}