import 'package:drift/drift.dart';
import 'package:ludo_rank/features/match_players/data/data_sources/local/match_player_dao.dart';
import 'package:ludo_rank/features/match_players/data/models/match_player_model.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

class MatchPlayerRepositoryImpl implements MatchPlayerRepository {
  final MatchPlayerDao dao;

  MatchPlayerRepositoryImpl(this.dao);

  @override
  Future<List<MatchPlayer>> getMatchPlayers(String matchId) async {
    final rows = await dao.getMatchPlayers(matchId);
    return rows.map(MatchPlayerModel.fromDrift).toList();
  }

  @override
  Future<MatchPlayer?> getMatchPlayer(String id) async {
    final row = await dao.getMatchPlayer(id);
    if (row == null) return null;
    return MatchPlayerModel.fromDrift(row);
  }

  @override
  Future<void> addPlayer(MatchPlayer player) async {
    final model = MatchPlayerModel.fromEntity(player);
    await dao.insertMatchPlayer(model.toCompanion());
  }

  @override
  Future<void> addPlayers(List<MatchPlayer> players) async {
    // تنفيذ العملية داخل Transaction لضمان استقرار قاعدة البيانات
    await dao.db.transaction(() async {
      for (final player in players) {
        await addPlayer(player);
      }
    });
  }

  @override
  Future<void> updateMatchPlayer(MatchPlayer player) async {
    final model = MatchPlayerModel.fromEntity(player);
    await dao.updateMatchPlayer(model.toCompanion());
  }

  @override
  Future<void> updateMatchPlayers(List<MatchPlayer> players) async {
    // Use case: تحديث الـ rank والـ points لجميع اللاعبين عند انتهاء المباراة
    await dao.db.transaction(() async {
      for (final player in players) {
        final model = MatchPlayerModel.fromEntity(player);

        await dao.updateMatchPlayer(
          model.toCompanion(),
        );
      }
    });
  }

  @override
  Future<void> removePlayer(String id) async {
    await dao.removePlayer(id);
  }

  @override
  Future<void> removeMatchPlayers(String matchId) async {
    await dao.removeMatchPlayers(matchId);
  }


}