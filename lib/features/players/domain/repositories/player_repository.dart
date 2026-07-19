import '../entities/player.dart';

abstract class PlayerRepository {
  Future<List<Player>> getAllPlayers();

  Future<Player?> getPlayerById(String id);

  Future<void> addPlayer(Player player);

  Future<void> updatePlayer(Player player);

  Future<void> deletePlayer(String id);
}