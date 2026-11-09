import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rank/core/database/database.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';
import 'package:ludo_rank/features/matches/data/repositories/match_game_state_repository_impl.dart';

void main() {
  late AppDatabase database;
  late MatchGameStateRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = MatchGameStateRepositoryImpl(
      database.matchDao,
    );

    await database.into(database.tournaments).insert(
      TournamentsCompanion.insert(
        id: 'tournament-1',
        name: 'Test Tournament',
        rounds: 1,
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    await database.matchDao.insertMatch(
      MatchesCompanion.insert(
        id: 'match-1',
        tournamentId: 'tournament-1',
        matchNumber: 1,
        status: 'playing',
        playersCount: const Value(2),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('MatchGameStateRepositoryImpl', () {
    test('saves and restores the same game state', () async {
      final originalState = _createGameState();

      await repository.saveGameState(
        matchId: 'match-1',
        state: originalState,
      );

      final restoredState = await repository.loadGameState(
        'match-1',
      );

      expect(restoredState, isNotNull);
      expect(restoredState, originalState);
    });

    test('returns null when no saved state exists', () async {
      final state = await repository.loadGameState('match-1');

      expect(state, isNull);
    });

    test('throws StateError when saving for missing match', () async {
      expect(
            () => repository.saveGameState(
          matchId: 'missing-match',
          state: _createGameState(),
        ),
        throwsStateError,
      );
    });

    test('clears saved state but preserves match record', () async {
      await repository.saveGameState(
        matchId: 'match-1',
        state: _createGameState(),
      );

      await repository.clearGameState('match-1');

      final restoredState = await repository.loadGameState(
        'match-1',
      );

      final match = await database.matchDao.getMatchById(
        'match-1',
      );

      expect(restoredState, isNull);
      expect(match, isNotNull);
      expect(match!.status, 'playing');
    });

    test('throws StateError when clearing missing match', () async {
      expect(
            () => repository.clearGameState('missing-match'),
        throwsStateError,
      );
    });

    test('throws FormatException when saved JSON is invalid', () async {
      await database.matchDao.saveGameStateJson(
        matchId: 'match-1',
        gameStateJson: '{invalid-json',
      );

      expect(
            () => repository.loadGameState('match-1'),
        throwsFormatException,
      );
    });
  });
}

LudoGameState _createGameState() {
  final player1 = LudoPlayer(
    id: 'match-player-1',
    playerId: 'player-1',
    name: 'Player One',
    color: LudoPlayerColor.red,
    seat: 1,
    tokens: const [],
  );

  final player2 = LudoPlayer(
    id: 'match-player-2',
    playerId: 'player-2',
    name: 'Player Two',
    color: LudoPlayerColor.green,
    seat: 2,
    tokens: const [],
  );

  return LudoGameState(
    players: [player1, player2],
    currentPlayerIndex: 0,
    turnState: TurnState.initial('player-1'),
    isStarted: true,
  );
}