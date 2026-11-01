
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

class TournamentStanding {
  final String playerId;
  final int points;
  final int matchesPlayed;
  final int wins;
  final int? bestRank;
  final int position;

  const TournamentStanding({
    required this.playerId,
    required this.points,
    required this.matchesPlayed,
    required this.wins,
    required this.bestRank,
    required this.position,
  });
}

class TournamentStandingsCalculator {
  const TournamentStandingsCalculator();

  List<TournamentStanding> calculate({
    required List<String> participantIds,
    required List<Match> matches,
    required List<MatchPlayer> matchPlayers,
  }) {
    final participantSet = participantIds.toSet();

    final points = <String, int>{};
    final matchesPlayed = <String, int>{};
    final wins = <String, int>{};
    final bestRanks = <String, int?>{};

    for (final playerId in participantSet) {
      points[playerId] = 0;
      matchesPlayed[playerId] = 0;
      wins[playerId] = 0;
      bestRanks[playerId] = null;
    }

    final completedMatchIds = matches
        .where((match) => match.status == MatchStatus.finished)
        .map((match) => match.id)
        .toSet();

    // يمنع احتساب نفس سجل اللاعب مرتين داخل المباراة نفسها.
    final processedEntries = <String>{};

    for (final result in matchPlayers) {
      if (!completedMatchIds.contains(result.matchId)) continue;
      if (!participantSet.contains(result.playerId)) continue;

      final entryKey = '${result.matchId}:${result.playerId}';
      if (!processedEntries.add(entryKey)) continue;

      points[result.playerId] =
          points[result.playerId]! + result.points;

      matchesPlayed[result.playerId] =
          matchesPlayed[result.playerId]! + 1;

      final rank = result.rank;

      if (rank == 1) {
        wins[result.playerId] = wins[result.playerId]! + 1;
      }

      if (rank != null &&
          (bestRanks[result.playerId] == null ||
              rank < bestRanks[result.playerId]!)) {
        bestRanks[result.playerId] = rank;
      }
    }

    final sortedPlayerIds = participantSet.toList()
      ..sort((a, b) {
        final pointsComparison = points[b]!.compareTo(points[a]!);
        if (pointsComparison != 0) return pointsComparison;

        // ترتيب ثابت عند تساوي النقاط، من غير كسر التعادل في المركز.
        return a.compareTo(b);
      });

    final standings = <TournamentStanding>[];
    var position = 0;
    int? previousPoints;

    for (var i = 0; i < sortedPlayerIds.length; i++) {
      final playerId = sortedPlayerIds[i];
      final playerPoints = points[playerId]!;

      if (previousPoints == null || playerPoints != previousPoints) {
        position = i + 1;
      }

      standings.add(
        TournamentStanding(
          playerId: playerId,
          points: playerPoints,
          matchesPlayed: matchesPlayed[playerId]!,
          wins: wins[playerId]!,
          bestRank: bestRanks[playerId],
          position: position,
        ),
      );

      previousPoints = playerPoints;
    }

    return List.unmodifiable(standings);
  }
}
