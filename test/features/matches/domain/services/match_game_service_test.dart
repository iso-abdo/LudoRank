import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_service.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_session.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_game_state_repository.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/services/ludo_game_engine.dart';

void main() {
  group('MatchGameService - 4 Players Integration', () {
    late FakeMatchRepository matchRepository;
    late FakeMatchPlayerRepository matchPlayerRepository;
    late MatchGameService service;
    late FakeMatchGameStateRepository gameStateRepository;

    late Match match;
    late List<MatchPlayer> players;

    setUp(() {
      matchRepository = FakeMatchRepository();
      matchPlayerRepository = FakeMatchPlayerRepository();
      gameStateRepository = FakeMatchGameStateRepository();

      service = MatchGameService(
        matchRepository: matchRepository,
        matchPlayerRepository: matchPlayerRepository,
        gameStateRepository: gameStateRepository,
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
      matchPlayerRepository.seed(players);
    });
    Future<LudoGameState> createSavedSnapshot() async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      // نسجل رمية حقيقية من خلال الـ Engine.
      // ده بيضمن إن Snapshot ناتجة من حالة لعب فعلية.
      session.engine.registerDiceRoll(
        value: 6,
        sequence: 1,
      );

      final snapshot = session.state;

      await gameStateRepository.saveGameState(
        matchId: 'match-1',
        state: snapshot,
      );

      return snapshot;
    }
    Future<MatchGameSession> createStartedSession() {
      return service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );
    }

    group('saveSnapshot', () {
      test('saves the initial state of a started playing match', () async {
        final session = await createStartedSession();

        final stateBeforeSave = session.state;

        await service.saveSnapshot(session: session);

        expect(gameStateRepository.saveCallCount, 1);
        expect(
          gameStateRepository.snapshots.containsKey('match-1'),
          isTrue,
        );
        expect(
          gameStateRepository.snapshots['match-1'],
          stateBeforeSave,
        );
      });

      test('saves the state after registering a dice roll', () async {
        final session = await createStartedSession();

        session.engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        final stateAfterRoll = session.state;

        await service.saveSnapshot(session: session);

        final savedState = gameStateRepository.snapshots['match-1'];

        expect(savedState, isNotNull);
        expect(savedState, stateAfterRoll);
        expect(savedState!.turnState.rolls.length, 1);
        expect(savedState.turnState.rolls.first.value, 6);
        expect(savedState.turnState.rolls.first.sequence, 1);
        expect(savedState.turnState.sixRollCount, 1);
      });

      test('saves the state after executing a legal token move', () async {
        final session = await createStartedSession();

        session.engine.registerDiceRoll(
          value: 1,
          sequence: 1,
        );

        final validMoves = session.engine.getValidMoves();

        expect(validMoves, isNotEmpty);

        session.engine.executeMove(validMoves.first);

        final stateAfterMove = session.state;

        await service.saveSnapshot(session: session);

        expect(
          gameStateRepository.snapshots['match-1'],
          stateAfterMove,
        );
      });

      test('uses the match id from the session when saving', () async {
        final session = await createStartedSession();

        await service.saveSnapshot(session: session);

        expect(
          gameStateRepository.snapshots.keys,
          contains(session.match.id),
        );
        expect(
          gameStateRepository.snapshots.keys,
          isNot(contains('another-match')),
        );
      });

      test('does not modify engine state while saving', () async {
        final session = await createStartedSession();

        session.engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        final stateBeforeSave = session.state;

        await service.saveSnapshot(session: session);

        expect(session.state, stateBeforeSave);
      });

      test('rejects a session whose match is not playing', () async {
        final session = await createStartedSession();

        final pendingSession = MatchGameSession(
          match: session.match.copyWith(
            status: MatchStatus.pending,
          ),
          matchPlayers: session.matchPlayers,
          engine: session.engine,
        );

        await expectLater(
          service.saveSnapshot(session: pendingSession),
          throwsA(isA<StateError>()),
        );

        expect(gameStateRepository.saveCallCount, 0);
        expect(gameStateRepository.snapshots, isEmpty);
      });

      test('rejects an engine that has not started', () async {
        final session = await createStartedSession();

        final notStartedEngine = LudoGameEngine(
          initialState: session.state.copyWith(
            isStarted: false,
          ),
        );

        final notStartedSession = MatchGameSession(
          match: session.match,
          matchPlayers: session.matchPlayers,
          engine: notStartedEngine,
        );

        await expectLater(
          service.saveSnapshot(session: notStartedSession),
          throwsA(isA<StateError>()),
        );

        expect(gameStateRepository.saveCallCount, 0);
        expect(gameStateRepository.snapshots, isEmpty);
      });

      test('rejects an invalid game state', () async {
        final session = await createStartedSession();

        final invalidEngine = LudoGameEngine(
          initialState: session.state.copyWith(
            currentPlayerIndex: 99,
          ),
        );

        final invalidSession = MatchGameSession(
          match: session.match,
          matchPlayers: session.matchPlayers,
          engine: invalidEngine,
        );

        await expectLater(
          service.saveSnapshot(session: invalidSession),
          throwsA(isA<StateError>()),
        );

        expect(gameStateRepository.saveCallCount, 0);
        expect(gameStateRepository.snapshots, isEmpty);
      });

      test('rejects a finished game state', () async {
        final session = await createStartedSession();

        final finishedEngine = LudoGameEngine(
          initialState: session.state.copyWith(
            isFinished: true,
          ),
        );

        final finishedSession = MatchGameSession(
          match: session.match,
          matchPlayers: session.matchPlayers,
          engine: finishedEngine,
        );

        await expectLater(
          service.saveSnapshot(session: finishedSession),
          throwsA(isA<StateError>()),
        );

        expect(gameStateRepository.saveCallCount, 0);
        expect(gameStateRepository.snapshots, isEmpty);
      });

      test('propagates repository errors when saving fails', () async {
        final session = await createStartedSession();

        gameStateRepository.throwExceptionOnSave = true;

        await expectLater(
          service.saveSnapshot(session: session),
          throwsA(isA<StateError>()),
        );

        expect(gameStateRepository.saveCallCount, 1);
        expect(gameStateRepository.snapshots, isEmpty);
      });

      test('does not modify engine state or match status when saving fails',
              () async {
            final session = await createStartedSession();

            session.engine.registerDiceRoll(
              value: 6,
              sequence: 1,
            );

            final stateBeforeSave = session.state;
            final statusBeforeSave = session.match.status;

            gameStateRepository.throwExceptionOnSave = true;

            await expectLater(
              service.saveSnapshot(session: session),
              throwsA(isA<StateError>()),
            );

            expect(session.state, stateBeforeSave);
            expect(session.match.status, statusBeforeSave);
            expect(gameStateRepository.snapshots, isEmpty);
          });
    });


    group('resumeMatch', () {


      test('restores a valid saved match snapshot', () async {
        final savedState = await createSavedSnapshot();

        final session = await service.resumeMatch(
          matchId: 'match-1',
        );

        // Match and session
        expect(session, isA<MatchGameSession>());
        expect(session.match.id, 'match-1');
        expect(session.match.status, MatchStatus.playing);

        // Engine status
        expect(session.isStarted, isTrue);
        expect(session.isFinished, isFalse);

        // Current player and turn
        expect(session.currentPlayerId, 'player-1');
        expect(
          session.state.currentPlayerIndex,
          savedState.currentPlayerIndex,
        );
        expect(
          session.state.turnState.playerId,
          savedState.turnState.playerId,
        );

        // Dice history
        expect(session.state.turnState.rolls, savedState.turnState.rolls);
        expect(session.state.turnState.rolls.length, 1);
        expect(session.state.turnState.rolls.first.value, 6);
        expect(session.state.turnState.rolls.first.sequence, 1);

        // Available rolls
        expect(
          session.state.turnState.availableRolls.rolls,
          savedState.turnState.availableRolls.rolls,
        );
        expect(
          session.state.turnState.availableRolls.rolls.length,
          1,
        );
        expect(
          session.state.turnState.availableRolls.rolls.first.value,
          6,
        );

        expect(session.state.turnState.sixRollCount, 1);

        // All players and their tokens must be restored.
        expect(session.state.players.length, 4);

        for (var index = 0; index < 4; index++) {
          final restoredPlayer = session.state.players[index];
          final savedPlayer = savedState.players[index];

          expect(restoredPlayer.playerId, savedPlayer.playerId);
          expect(restoredPlayer.seat, savedPlayer.seat);
          expect(restoredPlayer.name, savedPlayer.name);
          expect(restoredPlayer.tokens, savedPlayer.tokens);
        }

        // Persisted MatchPlayers
        expect(
          session.matchPlayers.map((player) => player.playerId).toList(),
          ['player-1', 'player-2', 'player-3', 'player-4'],
        );
      });

      test('rejects a match that does not exist', () async {
        await expectLater(
          service.resumeMatch(matchId: 'missing-match'),
          throwsA(isA<StateError>()),
        );
      });

      test('rejects a match that is not playing', () async {
        expect(match.status, MatchStatus.pending);

        await expectLater(
          service.resumeMatch(matchId: 'match-1'),
          throwsA(isA<StateError>()),
        );
      });

      test('rejects a match without a saved snapshot', () async {
        // Start the match so its status becomes Playing.
        // startMatch does not save a game snapshot.
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
          gameStateRepository.snapshots.containsKey('match-1'),
          isFalse,
        );

        await expectLater(
          service.resumeMatch(matchId: 'match-1'),
          throwsA(isA<StateError>()),
        );
      });

      test('propagates FormatException when snapshot loading fails', () async {
        await service.startMatch(
          matchId: 'match-1',
          playerNames: const {
            'player-1': 'Player 1',
            'player-2': 'Player 2',
            'player-3': 'Player 3',
            'player-4': 'Player 4',
          },
        );

        gameStateRepository.throwFormatExceptionOnLoad = true;

        await expectLater(
          service.resumeMatch(matchId: 'match-1'),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a snapshot incompatible with the match', () async {
        final validSnapshot = await createSavedSnapshot();

        final invalidSnapshot = validSnapshot.copyWith(
          currentPlayerIndex: 99,
        );

        await gameStateRepository.saveGameState(
          matchId: 'match-1',
          state: invalidSnapshot,
        );

        await expectLater(
          service.resumeMatch(matchId: 'match-1'),
          throwsA(isA<StateError>()),
        );
      });
    });


    test('starts a 4-player match and builds Ludo session', () async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      expect(session, isA<MatchGameSession>());

      expect(session.match.id, 'match-1');

      expect(session.match.status, MatchStatus.playing);

      expect(session.isStarted, isTrue);

      expect(session.state.players.length, 4);

      expect(session.state.currentPlayer.seat, 1);

      expect(session.state.players[0].playerId, 'player-1');

      expect(session.state.players[1].playerId, 'player-2');

      expect(session.state.players[2].playerId, 'player-3');

      expect(session.state.players[3].playerId, 'player-4');

      expect(session.state.players[0].tokens.length, 4);

      expect(session.state.players[1].tokens.length, 4);

      expect(session.state.players[2].tokens.length, 4);

      expect(session.state.players[3].tokens.length, 4);

      final storedMatch = await matchRepository.getById('match-1');

      expect(storedMatch?.status, MatchStatus.playing);
    });
    test('rejects starting an already playing match', () async {
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
        () => service.startMatch(
          matchId: 'match-1',
          playerNames: const {
            'player-1': 'Player 1',
            'player-2': 'Player 2',
            'player-3': 'Player 3',
            'player-4': 'Player 4',
          },
        ),
        throwsStateError,
      );

      final storedMatch = await matchRepository.getById('match-1');

      expect(storedMatch?.status, MatchStatus.playing);
    });
    test('rejects completing a pending match', () async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      // نحاكي أن حالة الـ Match المحفوظة رجعت Pending.
      await matchRepository.update(match.copyWith(status: MatchStatus.pending));

      final completedResult = GameResult(
        isFinished: true,
        players: const [
          GamePlayerResult(playerId: 'player-1', rank: 1, finished: true),
          GamePlayerResult(playerId: 'player-2', rank: 2, finished: true),
          GamePlayerResult(playerId: 'player-3', rank: 3, finished: true),
          GamePlayerResult(playerId: 'player-4', rank: 4, finished: true),
        ],
      );

      expect(
        () => service.completeMatchFromResult(
          session: session,
          result: completedResult,
        ),
        throwsStateError,
      );

      final storedMatch = await matchRepository.getById('match-1');

      expect(storedMatch?.status, MatchStatus.pending);
    });
    test('rejects completing a finished match', () async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      await matchRepository.update(
        match.copyWith(status: MatchStatus.finished),
      );

      final completedResult = GameResult(
        isFinished: true,
        players: const [
          GamePlayerResult(playerId: 'player-3', rank: 1, finished: true),
          GamePlayerResult(playerId: 'player-1', rank: 2, finished: true),
          GamePlayerResult(playerId: 'player-4', rank: 3, finished: true),
          GamePlayerResult(playerId: 'player-2', rank: 4, finished: true),
        ],
      );

      expect(
        () => service.completeMatchFromResult(
          session: session,
          result: completedResult,
        ),
        throwsStateError,
      );

      final storedMatch = await matchRepository.getById('match-1');

      expect(storedMatch?.status, MatchStatus.finished);
    });

    test('converts a completed GameResult to rank and points', () async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      final completedResult = GameResult(
        isFinished: true,
        players: const [
          GamePlayerResult(playerId: 'player-3', rank: 1, finished: true),
          GamePlayerResult(playerId: 'player-1', rank: 2, finished: true),
          GamePlayerResult(playerId: 'player-4', rank: 3, finished: true),
          GamePlayerResult(playerId: 'player-2', rank: 4, finished: false),
        ],
      );

      final updatedPlayers = await service.completeMatchFromResult(
        session: session,
        result: completedResult,
      );

      expect(updatedPlayers.length, 4);

      final player1 = updatedPlayers.firstWhere(
        (player) => player.playerId == 'player-1',
      );

      final player2 = updatedPlayers.firstWhere(
        (player) => player.playerId == 'player-2',
      );

      final player3 = updatedPlayers.firstWhere(
        (player) => player.playerId == 'player-3',
      );

      final player4 = updatedPlayers.firstWhere(
        (player) => player.playerId == 'player-4',
      );

      expect(player1.rank, 2);

      expect(player1.points, 3);

      expect(player1.finished, isTrue);

      expect(player2.rank, 4);

      expect(player2.points, 1);

      expect(player2.finished, isFalse);

      expect(player3.rank, 1);

      expect(player3.points, 4);

      expect(player3.finished, isTrue);

      expect(player4.rank, 3);

      expect(player4.points, 2);

      expect(player4.finished, isTrue);

      final storedMatch = await matchRepository.getById('match-1');

      expect(storedMatch?.status, MatchStatus.finished);

      final storedPlayers = await matchPlayerRepository.getMatchPlayers(
        'match-1',
      );

      final storedPlayer1 = storedPlayers.firstWhere(
        (player) => player.playerId == 'player-1',
      );

      final storedPlayer2 = storedPlayers.firstWhere(
        (player) => player.playerId == 'player-2',
      );

      final storedPlayer3 = storedPlayers.firstWhere(
        (player) => player.playerId == 'player-3',
      );

      final storedPlayer4 = storedPlayers.firstWhere(
        (player) => player.playerId == 'player-4',
      );

      expect(storedPlayer1.rank, 2);
      expect(storedPlayer1.finished, isTrue);

      expect(storedPlayer2.rank, 4);
      expect(storedPlayer2.finished, isFalse);

      expect(storedPlayer3.rank, 1);
      expect(storedPlayer3.finished, isTrue);

      expect(storedPlayer4.rank, 3);
      expect(storedPlayer4.finished, isTrue);
    });

    test('rejects an incomplete result', () async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      final incompleteResult = GameResult(
        isFinished: false,
        players: const [
          GamePlayerResult(playerId: 'player-1', rank: 1, finished: true),
        ],
      );

      expect(
        () => service.completeMatchFromResult(
          session: session,
          result: incompleteResult,
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate ranks', () async {
      final session = await service.startMatch(
        matchId: 'match-1',
        playerNames: const {
          'player-1': 'Player 1',
          'player-2': 'Player 2',
          'player-3': 'Player 3',
          'player-4': 'Player 4',
        },
      );

      final invalidResult = GameResult(
        isFinished: true,
        players: const [
          GamePlayerResult(playerId: 'player-1', rank: 1, finished: true),
          GamePlayerResult(playerId: 'player-2', rank: 1, finished: true),
          GamePlayerResult(playerId: 'player-3', rank: 3, finished: true),
          GamePlayerResult(playerId: 'player-4', rank: 4, finished: true),
        ],
      );

      expect(
        () => service.completeMatchFromResult(
          session: session,
          result: invalidResult,
        ),
        throwsStateError,
      );
    });
  });
}

class FakeMatchRepository implements MatchRepository {
  final Map<String, Match> _matches = {};


  void seed(Match match) {
    _matches[match.id] = match;
  }

  @override
  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    return _matches.values
        .where((match) => match.tournamentId == tournamentId)
        .toList();
  }

  @override
  Future<List<Match>> getAllMatches() async {
    return _matches.values.toList();
  }

  @override
  Future<Match?> getById(String id) async {
    return _matches[id];
  }

  @override
  Future<void> create(Match match) async {
    _matches[match.id] = match;
  }

  @override
  Future<void> update(Match match) async {
    _matches[match.id] = match;
  }

  @override
  Future<void> delete(String id) async {
    _matches.remove(id);
  }
}

class FakeMatchPlayerRepository implements MatchPlayerRepository {
  final Map<String, MatchPlayer> _players = {};

  void seed(List<MatchPlayer> players) {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<List<MatchPlayer>> getMatchPlayers(String matchId) async {
    final result = _players.values
        .where((player) => player.matchId == matchId)
        .toList();

    result.sort((a, b) => a.seat.compareTo(b.seat));

    return result;
  }

  @override
  Future<MatchPlayer?> getMatchPlayer(String id) async {
    return _players[id];
  }

  @override
  Future<void> addPlayer(MatchPlayer player) async {
    _players[player.id] = player;
  }

  @override
  Future<void> addPlayers(List<MatchPlayer> players) async {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<void> updateMatchPlayer(MatchPlayer player) async {
    _players[player.id] = player;
  }

  @override
  Future<void> updateMatchPlayers(List<MatchPlayer> players) async {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<void> removePlayer(String id) async {
    _players.remove(id);
  }

  @override
  Future<void> removeMatchPlayers(String matchId) async {
    final ids = _players.values
        .where((player) => player.matchId == matchId)
        .map((player) => player.id)
        .toList();

    for (final id in ids) {
      _players.remove(id);
    }
  }
}

class FakeMatchGameStateRepository implements MatchGameStateRepository {
  final Map<String, LudoGameState> snapshots = {};

  bool throwFormatExceptionOnLoad = false;
  bool throwExceptionOnSave = false;

  int saveCallCount = 0;

  @override
  Future<void> saveGameState({
    required String matchId,
    required LudoGameState state,
  }) async {
    saveCallCount++;

    if (throwExceptionOnSave) {
      throw StateError('Snapshot save failed');
    }

    snapshots[matchId] = state;
  }

  @override
  Future<LudoGameState?> loadGameState(String matchId) async {
    if (throwFormatExceptionOnLoad) {
      throw const FormatException('Invalid snapshot JSON');
    }

    return snapshots[matchId];
  }

  @override
  Future<void> clearGameState(String matchId) async {
    snapshots.remove(matchId);
  }
}