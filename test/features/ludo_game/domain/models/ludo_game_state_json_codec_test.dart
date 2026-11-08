
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/dice_roll.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state_json_codec.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

void main() {
  group('LudoGameStateJsonCodec', () {
    late LudoGameState originalState;

    setUp(() {
      originalState = _createGameState();
    });

    test('encodes game state into valid JSON', () {
      final json = LudoGameStateJsonCodec.encode(originalState);

      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['formatVersion'], 1);
      expect(decoded['state'], isA<Map<String, dynamic>>());
    });

    test('restores exactly the same game state after round trip', () {
      final json = LudoGameStateJsonCodec.encode(originalState);

      final restored = LudoGameStateJsonCodec.decode(json);

      expect(restored, originalState);
    });

    test('preserves token movement and special states', () {
      final json = LudoGameStateJsonCodec.encode(originalState);

      final restored = LudoGameStateJsonCodec.decode(json);

      final token = restored.players.first.tokens.first;

      expect(token.position, const Position(row: 8, column: 6));
      expect(token.positionInPath, 51);
      expect(token.state, LudoTokenState.safe);
      expect(token.homeEntryPending, true);
    });

    test('preserves rolls and available rolls separately', () {
      final json = LudoGameStateJsonCodec.encode(originalState);

      final restored = LudoGameStateJsonCodec.decode(json);

      expect(
        restored.turnState.rolls,
        [
          const DiceRoll(value: 6, sequence: 1),
          const DiceRoll(value: 4, sequence: 2),
          const DiceRoll(value: 6, sequence: 3),
        ],
      );

      expect(
        restored.turnState.availableRolls.values,
        [4, 6],
      );

      expect(restored.turnState.sixRollCount, 2);
      expect(restored.turnState.phase, TurnPhase.playing);
    });

    test('preserves empty rolls and finished player ids', () {
      final state = originalState.copyWith(
        turnState: TurnState.initial('player-1'),
        finishedPlayerIds: const [],
      );

      final restored = LudoGameStateJsonCodec.decode(
        LudoGameStateJsonCodec.encode(state),
      );

      expect(restored.turnState.rolls, isEmpty);
      expect(restored.turnState.availableRolls.rolls, isEmpty);
      expect(restored.finishedPlayerIds, isEmpty);
    });

    test('throws FormatException for invalid JSON', () {
      expect(
            () => LudoGameStateJsonCodec.decode('{invalid json'),
        throwsFormatException,
      );
    });

    test('throws FormatException for unsupported format version', () {
      final json = jsonEncode({
        'formatVersion': 999,
        'state': {},
      });

      expect(
            () => LudoGameStateJsonCodec.decode(json),
        throwsFormatException,
      );
    });

    test('throws FormatException when required data is missing', () {
      final json = jsonEncode({
        'formatVersion': 1,
        'state': {
          'players': [],
        },
      });

      expect(
            () => LudoGameStateJsonCodec.decode(json),
        throwsFormatException,
      );
    });

    test('throws FormatException for unknown enum values', () {
      final map = jsonDecode(
        LudoGameStateJsonCodec.encode(originalState),
      ) as Map<String, dynamic>;

      final state = map['state'] as Map<String, dynamic>;
      final players = state['players'] as List<dynamic>;
      final player = players.first as Map<String, dynamic>;

      player['color'] = 'purple';

      expect(
            () => LudoGameStateJsonCodec.decode(jsonEncode(map)),
        throwsFormatException,
      );
    });
  });
}

LudoGameState _createGameState() {
  const player1Id = 'player-1';
  const player2Id = 'player-2';

  final player1 = LudoPlayer(
    id: 'match-player-1',
    playerId: player1Id,
    name: 'Player One',
    color: LudoPlayerColor.red,
    seat: 1,
    hasCaptured: true,
    tokens: const [
      LudoToken(
        id: 'token-1',
        playerId: player1Id,
        tokenIndex: 0,
        position: Position(row: 8, column: 6),
        positionInPath: 51,
        state: LudoTokenState.safe,
        homeEntryPending: true,
      ),
      LudoToken(
        id: 'token-2',
        playerId: player1Id,
        tokenIndex: 1,
        position: Position(row: 0, column: 0),
        positionInPath: -1,
        state: LudoTokenState.initial,
      ),
    ],
  );

  final player2 = LudoPlayer(
    id: 'match-player-2',
    playerId: player2Id,
    name: 'Player Two',
    color: LudoPlayerColor.green,
    seat: 2,
    tokens: const [
      LudoToken(
        id: 'token-3',
        playerId: player2Id,
        tokenIndex: 0,
        position: Position(row: 6, column: 8),
        positionInPath: 12,
        state: LudoTokenState.normal,
      ),
    ],
  );

  return LudoGameState(
    players: [player1, player2],
    currentPlayerIndex: 0,
    turnState: TurnState(
      playerId: player1Id,
      rolls: const [
        DiceRoll(value: 6, sequence: 1),
        DiceRoll(value: 4, sequence: 2),
        DiceRoll(value: 6, sequence: 3),
      ],
      availableRolls: AvailableRolls(
        rolls: const [
          DiceRoll(value: 4, sequence: 2),
          DiceRoll(value: 6, sequence: 3),
        ],
      ),
      sixRollCount: 2,
      phase: TurnPhase.playing,
    ),
    isStarted: true,
    isFinished: false,
    finishedPlayerIds: const [],
  );
}
