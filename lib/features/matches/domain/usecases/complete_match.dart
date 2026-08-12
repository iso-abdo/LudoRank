/*import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';

class CompleteMatch {
  final MatchRepository matchRepository;
  final MatchPlayerRepository matchPlayerRepository;

  CompleteMatch({
    required this.matchRepository,
    required this.matchPlayerRepository,
  });

  Future<void> call({
    required Match match,
    required List<MatchPlayerResult> results,
  }) async {
    _validateResults(match, results);

    final currentPlayers =
    await matchPlayerRepository.getMatchPlayers(match.id);

    final updatedPlayers = currentPlayers.map((player) {
      final result = results.firstWhere(
            (result) => result.playerId == player.playerId,
      );

      return player.copyWith(
        rank: result.rank,
        points: result.points,
        finished: result.finished,
      );
    }).toList();

    await matchPlayerRepository.updateMatchPlayers(
      updatedPlayers,
    );

    final updatedMatch = match.copyWith(
      status: MatchStatus.finished,
      updatedAt: DateTime.now(),
    );

    await matchRepository.update(updatedMatch);
  }

  void _validateResults(
      Match match,
      List<MatchPlayerResult> results,
      ) {
    if (results.length != match.playersCount) {
      throw ArgumentError(
        'عدد نتائج اللاعبين لا يطابق عدد لاعبي المباراة.',
      );
    }

    final playerIds =
    results.map((e) => e.playerId).toSet();

    if (playerIds.length != results.length) {
      throw ArgumentError(
        'لا يمكن تكرار اللاعب في نتيجة المباراة.',
      );
    }

    final ranks =
    results.map((e) => e.rank).toSet();

    if (ranks.length != results.length) {
      throw ArgumentError(
        'لا يمكن تكرار المركز في نتيجة المباراة.',
      );
    }
  }
}*/