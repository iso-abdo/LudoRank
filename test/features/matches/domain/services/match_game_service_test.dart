import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_service.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_session.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

void main() {
  group(
    'MatchGameService - 4 Players Integration',
        () {
      late FakeMatchRepository matchRepository;
      late FakeMatchPlayerRepository matchPlayerRepository;
      late MatchGameService service;

      late Match match;
      late List<MatchPlayer> players;

      setUp(
            () {
          matchRepository =
              FakeMatchRepository();

          matchPlayerRepository =
              FakeMatchPlayerRepository();

          service = MatchGameService(
            matchRepository: matchRepository,
            matchPlayerRepository:
            matchPlayerRepository,
          );

          final now = DateTime(2026, 1, 1);

          match = Match(
            id: 'match-1',
            tournamentId: 'tournament-1',
            playersCount: 4,
            status: MatchStatus.pending,
            createdAt: now,
            updatedAt: now,
          );

          players = [
            MatchPlayer(
              id: 'mp-1',
              matchId: 'match-1',
              playerId: 'player-1',
              seat: 1,
              rank: null,
              points: 0,
              finished: false,
            ),
            MatchPlayer(
              id: 'mp-2',
              matchId: 'match-1',
              playerId: 'player-2',
              seat: 2,
              rank: null,
              points: 0,
              finished: false,
            ),
            MatchPlayer(
              id: 'mp-3',
              matchId: 'match-1',
              playerId: 'player-3',
              seat: 3,
              rank: null,
              points: 0,
              finished: false,
            ),
            MatchPlayer(
              id: 'mp-4',
              matchId: 'match-1',
              playerId: 'player-4',
              seat: 4,
              rank: null,
              points: 0,
              finished: false,
            ),
          ];

          matchRepository.seed(match);
          matchPlayerRepository.seed(
            players,
          );
        },
      );

      test(
        'starts a 4-player match and builds Ludo session',
            () async {
          final session =
          await service.startMatch(
            matchId: 'match-1',
            playerNames: const {
              'player-1': 'Player 1',
              'player-2': 'Player 2',
              'player-3': 'Player 3',
              'player-4': 'Player 4',
            },
          );

          expect(
            session,
            isA<MatchGameSession>(),
          );

          expect(
            session.match.id,
            'match-1',
          );

          expect(
            session.match.status,
            MatchStatus.playing,
          );

          expect(
            session.isStarted,
            isTrue,
          );

          expect(
            session.state.players.length,
            4,
          );

          expect(
            session.state.currentPlayer.seat,
            1,
          );

          expect(
            session.state.players[0].playerId,
            'player-1',
          );

          expect(
            session.state.players[1].playerId,
            'player-2',
          );

          expect(
            session.state.players[2].playerId,
            'player-3',
          );

          expect(
            session.state.players[3].playerId,
            'player-4',
          );

          expect(
            session.state.players[0].tokens.length,
            4,
          );

          expect(
            session.state.players[1].tokens.length,
            4,
          );

          expect(
            session.state.players[2].tokens.length,
            4,
          );

          expect(
            session.state.players[3].tokens.length,
            4,
          );

          final storedMatch =
          await matchRepository.getById(
            'match-1',
          );

          expect(
            storedMatch?.status,
            MatchStatus.playing,
          );
        },
      );

      test(
        'converts a completed GameResult to rank and points',
            () async {
          final session =
          await service.startMatch(
            matchId: 'match-1',
            playerNames: const {
              'player-1': 'Player 1',
              'player-2': 'Player 2',
              'player-3': 'Player 3',
              'player-4': 'Player 4',
            },
          );

          final completedResult =
          GameResult(
            isFinished: true,
            players: const [
              GamePlayerResult(
                playerId: 'player-3',
                rank: 1,
                finished: true,
              ),
              GamePlayerResult(
                playerId: 'player-1',
                rank: 2,
                finished: true,
              ),
              GamePlayerResult(
                playerId: 'player-4',
                rank: 3,
                finished: true,
              ),
              GamePlayerResult(
                playerId: 'player-2',
                rank: 4,
                finished: true,
              ),
            ],
          );

          final updatedPlayers =
          await service.completeMatchFromResult(
            session: session,
            result: completedResult,
          );

          expect(
            updatedPlayers.length,
            4,
          );

          final player1 =
          updatedPlayers.firstWhere(
                (player) =>
            player.playerId == 'player-1',
          );

          final player2 =
          updatedPlayers.firstWhere(
                (player) =>
            player.playerId == 'player-2',
          );

          final player3 =
          updatedPlayers.firstWhere(
                (player) =>
            player.playerId == 'player-3',
          );

          final player4 =
          updatedPlayers.firstWhere(
                (player) =>
            player.playerId == 'player-4',
          );

          expect(
            player1.rank,
            2,
          );

          expect(
            player1.points,
            3,
          );

          expect(
            player1.finished,
            isTrue,
          );

          expect(
            player2.rank,
            4,
          );

          expect(
            player2.points,
            1,
          );

          expect(
            player2.finished,
            isTrue,
          );

          expect(
            player3.rank,
            1,
          );

          expect(
            player3.points,
            4,
          );

          expect(
            player3.finished,
            isTrue,
          );

          expect(
            player4.rank,
            3,
          );

          expect(
            player4.points,
            2,
          );

          expect(
            player4.finished,
            isTrue,
          );

          final storedMatch =
          await matchRepository.getById(
            'match-1',
          );

          expect(
            storedMatch?.status,
            MatchStatus.finished,
          );

          final storedPlayers =
          await matchPlayerRepository
              .getMatchPlayers(
            'match-1',
          );

          expect(
            storedPlayers.every(
                  (player) =>
              player.finished &&
                  player.rank != null,
            ),
            isTrue,
          );
        },
      );

      test(
        'rejects an incomplete result',
            () async {
          final session =
          await service.startMatch(
            matchId: 'match-1',
            playerNames: const {
              'player-1': 'Player 1',
              'player-2': 'Player 2',
              'player-3': 'Player 3',
              'player-4': 'Player 4',
            },
          );

          final incompleteResult =
          GameResult(
            isFinished: false,
            players: const [
              GamePlayerResult(
                playerId: 'player-1',
                rank: 1,
                finished: true,
              ),
            ],
          );

          expect(
                () => service.completeMatchFromResult(
              session: session,
              result: incompleteResult,
            ),
            throwsStateError,
          );
        },
      );

      test(
        'rejects duplicate ranks',
            () async {
          final session =
          await service.startMatch(
            matchId: 'match-1',
            playerNames: const {
              'player-1': 'Player 1',
              'player-2': 'Player 2',
              'player-3': 'Player 3',
              'player-4': 'Player 4',
            },
          );

          final invalidResult =
          GameResult(
            isFinished: true,
            players: const [
              GamePlayerResult(
                playerId: 'player-1',
                rank: 1,
                finished: true,
              ),
              GamePlayerResult(
                playerId: 'player-2',
                rank: 1,
                finished: true,
              ),
              GamePlayerResult(
                playerId: 'player-3',
                rank: 3,
                finished: true,
              ),
              GamePlayerResult(
                playerId: 'player-4',
                rank: 4,
                finished: true,
              ),
            ],
          );

          expect(
                () => service.completeMatchFromResult(
              session: session,
              result: invalidResult,
            ),
            throwsStateError,
          );
        },
      );
    },
  );
}

class FakeMatchRepository
    implements MatchRepository {
  final Map<String, Match> _matches = {};

  void seed(Match match) {
    _matches[match.id] = match;
  }

  @override
  Future<List<Match>> getTournamentMatches(
      String tournamentId,
      ) async {
    return _matches.values
        .where(
          (match) =>
      match.tournamentId ==
          tournamentId,
    )
        .toList();
  }

  @override
  Future<List<Match>> getAllMatches() async {
    return _matches.values.toList();
  }

  @override
  Future<Match?> getById(
      String id,
      ) async {
    return _matches[id];
  }

  @override
  Future<void> create(
      Match match,
      ) async {
    _matches[match.id] = match;
  }

  @override
  Future<void> update(
      Match match,
      ) async {
    _matches[match.id] = match;
  }

  @override
  Future<void> delete(
      String id,
      ) async {
    _matches.remove(id);
  }
}

class FakeMatchPlayerRepository
    implements MatchPlayerRepository {
  final Map<String, MatchPlayer> _players =
  {};

  void seed(
      List<MatchPlayer> players,
      ) {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<List<MatchPlayer>> getMatchPlayers(
      String matchId,
      ) async {
    final result = _players.values
        .where(
          (player) =>
      player.matchId == matchId,
    )
        .toList();

    result.sort(
          (a, b) => a.seat.compareTo(b.seat),
    );

    return result;
  }

  @override
  Future<MatchPlayer?> getMatchPlayer(
      String id,
      ) async {
    return _players[id];
  }

  @override
  Future<void> addPlayer(
      MatchPlayer player,
      ) async {
    _players[player.id] = player;
  }

  @override
  Future<void> addPlayers(
      List<MatchPlayer> players,
      ) async {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<void> updateMatchPlayer(
      MatchPlayer player,
      ) async {
    _players[player.id] = player;
  }

  @override
  Future<void> updateMatchPlayers(
      List<MatchPlayer> players,
      ) async {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<void> removePlayer(
      String id,
      ) async {
    _players.remove(id);
  }

  @override
  Future<void> removeMatchPlayers(
      String matchId,
      ) async {
    final ids = _players.values
        .where(
          (player) =>
      player.matchId == matchId,
    )
        .map(
          (player) => player.id,
    )
        .toList();

    for (final id in ids) {
      _players.remove(id);
    }
  }
}