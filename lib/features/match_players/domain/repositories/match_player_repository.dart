import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

abstract class MatchPlayerRepository {
  Future<List<MatchPlayer>> getMatchPlayers(String matchId);

  Future<void> addPlayer(MatchPlayer player);

  Future<void> addPlayers(List<MatchPlayer> players);

  Future<void> removePlayer(String id);

  Future<void> removeMatchPlayers(String matchId);
}