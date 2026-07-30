import '../entities/tournament.dart';

abstract interface class TournamentRepository {
  Future<List<Tournament>> getAllTournaments();

  Future<Tournament?> getTournamentById(String id);

  Future<void> addTournament(Tournament tournament);

  Future<void> updateTournament(Tournament tournament);

  Future<void> deleteTournament(String id);
}