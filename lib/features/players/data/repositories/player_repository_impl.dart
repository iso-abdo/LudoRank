import 'package:ludo_rank/features/players/data/data_sources/local/player_dao.dart';
import 'package:ludo_rank/features/players/data/models/player_model.dart';
import 'package:ludo_rank/features/players/domain/entities/player.dart';
import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerDao dao;

  PlayerRepositoryImpl(this.dao);

  @override
  Future<List<Player>> getAllPlayers() async {
    final rows = await dao.getAllPlayers();
    return rows.map(PlayerModel.fromDrift).toList();
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    final row = await dao.getPlayerById(id);

    if (row == null) return null;

    return PlayerModel.fromDrift(row);
  }

  @override
  Future<void> addPlayer(Player player) async {
    final model = PlayerModel.fromEntity(player);

    await dao.insertPlayer(model.toCompanion());
  }

  @override
  Future<void> updatePlayer(Player player) async {
    final model = PlayerModel.fromEntity(player);

    await dao.updatePlayer(model.toCompanion());
  }

  @override
  Future<void> deletePlayer(String id) async {
    await dao.deletePlayer(id);
  }
}