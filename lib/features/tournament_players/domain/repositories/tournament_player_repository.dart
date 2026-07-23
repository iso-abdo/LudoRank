import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';

abstract class TournamentPlayerRepository {
  Future<List<TournamentPlayer>> getTournamentPlayers(
      String tournamentId,
      );

  Future<void> addPlayer(
      TournamentPlayer player,
      );

  Future<void> removePlayer(
      String id,
      );

  Future<void> removeTournamentPlayers(
      String tournamentId,
      );
}