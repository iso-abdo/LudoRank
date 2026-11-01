
import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/tournaments/domain/services/tournament_standings_calculator.dart';

void main() {
  const calculator = TournamentStandingsCalculator();

  final now = DateTime(2026, 1, 1);

  Match makeMatch(String id, MatchStatus status) {
    return Match(
      id: id,
      tournamentId: 'tournament-1',
      playersCount: 2,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  MatchPlayer makeResult({
    required String id,
    required String matchId,
    required String playerId,
    required int points,
    int? rank,
  }) {
    return MatchPlayer(
      id: id,
      matchId: matchId,
      playerId: playerId,
      seat: 1,
      points: points,
      rank: rank,
      finished: true,
    );
  }

  group('TournamentStandingsCalculator', () {
    test('keeps participants who have not played with zero points', () {
      final standings = calculator.calculate(
        participantIds: ['p1', 'p2', 'p3'],
        matches: [makeMatch('m1', MatchStatus.finished)],
        matchPlayers: [
          makeResult(
            id: 'r1',
            matchId: 'm1',
            playerId: 'p1',
            points: 2,
            rank: 1,
          ),
          makeResult(
            id: 'r2',
            matchId: 'm1',
            playerId: 'p2',
            points: 1,
            rank: 2,
          ),
        ],
      );

      expect(standings.map((s) => s.playerId).toList(),
          ['p1', 'p2', 'p3']);
      expect(standings[2].points, 0);
      expect(standings[2].matchesPlayed, 0);
      expect(standings[2].wins, 0);
      expect(standings[2].bestRank, isNull);
    });

    test('ignores results from unfinished matches', () {
      final standings = calculator.calculate(
        participantIds: ['p1', 'p2'],
        matches: [
          makeMatch('m1', MatchStatus.finished),
          makeMatch('m2', MatchStatus.playing),
        ],
        matchPlayers: [
          makeResult(
            id: 'r1',
            matchId: 'm1',
            playerId: 'p1',
            points: 2,
            rank: 1,
          ),
          makeResult(
            id: 'r2',
            matchId: 'm2',
            playerId: 'p1',
            points: 100,
            rank: 2,
          ),
        ],
      );

      expect(standings.firstWhere((s) => s.playerId == 'p1').points, 2);
      expect(
        standings.firstWhere((s) => s.playerId == 'p1').matchesPlayed,
        1,
      );
    });

    test('calculates wins, matches played, and best rank', () {
      final standings = calculator.calculate(
        participantIds: ['p1', 'p2'],
        matches: [
          makeMatch('m1', MatchStatus.finished),
          makeMatch('m2', MatchStatus.finished),
        ],
        matchPlayers: [
          makeResult(
            id: 'r1',
            matchId: 'm1',
            playerId: 'p1',
            points: 2,
            rank: 1,
          ),
          makeResult(
            id: 'r2',
            matchId: 'm1',
            playerId: 'p2',
            points: 1,
            rank: 2,
          ),
          makeResult(
            id: 'r3',
            matchId: 'm2',
            playerId: 'p1',
            points: 1,
            rank: 2,
          ),
          makeResult(
            id: 'r4',
            matchId: 'm2',
            playerId: 'p2',
            points: 2,
            rank: 1,
          ),
        ],
      );

      final p1 = standings.firstWhere((s) => s.playerId == 'p1');
      final p2 = standings.firstWhere((s) => s.playerId == 'p2');

      expect(p1.points, 3);
      expect(p1.matchesPlayed, 2);
      expect(p1.wins, 1);
      expect(p1.bestRank, 1);

      expect(p2.points, 3);
      expect(p2.matchesPlayed, 2);
      expect(p2.wins, 1);
      expect(p2.bestRank, 1);

      expect(p1.position, 1);
      expect(p2.position, 1);
    });

    test('uses competition ranking for tied points', () {
      final standings = calculator.calculate(
        participantIds: ['p1', 'p2', 'p3'],
        matches: [makeMatch('m1', MatchStatus.finished)],
        matchPlayers: [
          makeResult(
            id: 'r1',
            matchId: 'm1',
            playerId: 'p1',
            points: 3,
            rank: 1,
          ),
          makeResult(
            id: 'r2',
            matchId: 'm1',
            playerId: 'p2',
            points: 3,
            rank: 2,
          ),
          makeResult(
            id: 'r3',
            matchId: 'm1',
            playerId: 'p3',
            points: 1,
            rank: 3,
          ),
        ],
      );

      final positions = {
        for (final standing in standings)
          standing.playerId: standing.position,
      };

      expect(positions['p1'], 1);
      expect(positions['p2'], 1);
      expect(positions['p3'], 3);
    });

    test('does not count duplicate player entries twice', () {
      final standings = calculator.calculate(
        participantIds: ['p1'],
        matches: [makeMatch('m1', MatchStatus.finished)],
        matchPlayers: [
          makeResult(
            id: 'r1',
            matchId: 'm1',
            playerId: 'p1',
            points: 2,
            rank: 1,
          ),
          makeResult(
            id: 'r1-duplicate',
            matchId: 'm1',
            playerId: 'p1',
            points: 2,
            rank: 1,
          ),
        ],
      );

      expect(standings.single.points, 2);
      expect(standings.single.matchesPlayed, 1);
      expect(standings.single.wins, 1);
    });

    test('returns no standings when there are no participants', () {
      final standings = calculator.calculate(
        participantIds: [],
        matches: [],
        matchPlayers: [],
      );

      expect(standings, isEmpty);
    });
  });
}
