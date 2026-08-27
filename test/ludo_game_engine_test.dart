import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/services/ludo_game_engine.dart';

void main() {
  group('LudoGameEngine - Fast Mode', () {
    // ==========================================================
    // Helpers
    // ==========================================================

    LudoToken createToken({
      required String playerId,
      required int tokenIndex,
      LudoTokenState state = LudoTokenState.initial,
      int positionInPath = -1,
      Position? position,
    }) {
      return LudoToken(
        id: '$playerId-token-$tokenIndex',
        playerId: playerId,
        tokenIndex: tokenIndex,
        position: position ??
            const Position(
              row: 0,
              column: 0,
            ),
        positionInPath: positionInPath,
        state: state,
      );
    }

    LudoPlayer createPlayer({
      required String playerId,
      required int seat,
      LudoPlayerColor color = LudoPlayerColor.green,
      List<LudoToken>? tokens,
    }) {
      return LudoPlayer(
        id: playerId,
        playerId: playerId,
        name: playerId,
        color: color,
        seat: seat,
        tokens: tokens ??
            List.generate(
              4,
                  (index) => createToken(
                playerId: playerId,
                tokenIndex: index,
              ),
            ),
      );
    }

    LudoGameEngine createEngine({
      required List<LudoPlayer> players,
    }) {
      final state = LudoGameState.initial(
        players: players,
      );

      final engine = LudoGameEngine(
        initialState: state,
      );

      engine.startGame();

      return engine;
    }

    // ==========================================================
    // 1. Roll 4
    // ==========================================================

    test(
      'Roll 4 starts the playing phase and creates valid moves',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.playing,
        );

        expect(
          engine.state.turnState.rolls.length,
          1,
        );

        expect(
          engine.state.turnState.rolls.first.value,
          4,
        );

        expect(
          engine.state.turnState.availableRolls.count,
          1,
        );

        expect(
          engine.state.turnState.sixRollCount,
          0,
        );

        final moves = engine.getValidMoves();

        expect(
          moves,
          isNotEmpty,
        );

        expect(
          moves.whereType<MoveToken>().any(
                (move) =>
            move.tokenId ==
                'player-1-token-0' &&
                move.steps == 4 &&
                move.rollSequence == 1,
          ),
          isTrue,
        );
      },
    );

    // ==========================================================
    // 2. Roll 6 -> Roll 4
    // ==========================================================

    test(
      'Roll 6 then 4 keeps both rolls available',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6],
        );

        expect(
          engine.state.turnState.sixRollCount,
          1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.playing,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 4],
        );

        expect(
          engine.state.turnState.sixRollCount,
          1,
        );

        final moves = engine.getValidMoves();

        expect(
          moves,
          isNotEmpty,
        );

        expect(
          moves.whereType<MoveToken>().any(
                (move) =>
            move.steps == 6 &&
                move.rollSequence == 1,
          ),
          isTrue,
        );

        expect(
          moves.whereType<MoveToken>().any(
                (move) =>
            move.steps == 4 &&
                move.rollSequence == 2,
          ),
          isTrue,
        );
      },
    );

    // ==========================================================
    // 3. Roll 6 -> Roll 6 -> Roll 4
    // ==========================================================

    test(
      'Roll 6 -> 6 -> 4 creates three available rolls',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 2,
        );

        expect(
          engine.state.turnState.availableRolls.count,
          2,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
        );

        expect(
          engine.state.turnState.sixRollCount,
          2,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 3,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.playing,
        );

        expect(
          engine.state.turnState.rolls
              .map((roll) => roll.value)
              .toList(),
          [6, 6, 4],
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 6, 4],
        );

        expect(
          engine.state.turnState.sixRollCount,
          2,
        );

        expect(
          engine.getValidMoves(),
          isNotEmpty,
        );
      },
    );

    // ==========================================================
    // 4. Roll 6 -> 6 -> 6
    // ==========================================================

    test(
      'Three six rolls in the same turn cancel the turn',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        expect(
          engine.currentPlayer.playerId,
          'player-1',
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 2,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 3,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
        );

        expect(
          engine.state.turnState.rolls,
          isEmpty,
        );

        expect(
          engine.state.turnState.availableRolls.isEmpty,
          isTrue,
        );

        expect(
          engine.state.turnState.sixRollCount,
          0,
        );
      },
    );

    // ==========================================================
    // 5. 6 -> 4 -> 6
    // ==========================================================

    test(
      'Six roll count continues even when a non-six roll appears',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        expect(
          engine.state.turnState.sixRollCount,
          1,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 3,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
        );

        expect(
          engine.state.turnState.sixRollCount,
          2,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 4, 6],
        );
      },
    );

    // ==========================================================
    // 6. 6 -> 4 -> 6 -> 3 -> 6
    // ==========================================================

    test(
      'Three six rolls cancel the turn even when they are not consecutive',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 3,
        );

        expect(
          engine.state.turnState.sixRollCount,
          2,
        );

        engine.registerDiceRoll(
          value: 3,
          sequence: 4,
        );

        // 3 does not reset sixRollCount.
        expect(
          engine.state.turnState.sixRollCount,
          2,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 5,
        );

        expect(
          engine.state.turnState.sixRollCount,
          0,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );

        expect(
          engine.state.turnState.availableRolls.isEmpty,
          isTrue,
        );
      },
    );

    // ==========================================================
    // 7. Player can use different rolls
    // ==========================================================

    test(
      'Player can use different rolls on different tokens',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        final moves = engine.getValidMoves();

        final moveSix =
        moves.whereType<MoveToken>().firstWhere(
              (move) =>
          move.tokenId ==
              'player-1-token-0' &&
              move.steps == 6 &&
              move.rollSequence == 1,
        );

        engine.executeMove(moveSix);

        expect(
          engine.state.turnState.availableRolls.values,
          [4],
        );

        expect(
          engine.state.currentPlayer.tokens
              .firstWhere(
                (token) =>
            token.tokenIndex == 0,
          )
              .positionInPath,
          6,
        );

        final nextMoves =
        engine.getValidMoves();

        expect(
          nextMoves.whereType<MoveToken>().any(
                (move) =>
            move.steps == 4 &&
                move.rollSequence == 2,
          ),
          isTrue,
        );
      },
    );

    // ==========================================================
    // 8. Consume rolls one by one
    // ==========================================================

    test(
      'Available rolls are consumed one by one',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 4],
        );

        final moveSix =
        engine.getValidMoves()
            .whereType<MoveToken>()
            .firstWhere(
              (move) =>
          move.tokenId ==
              'player-1-token-0' &&
              move.steps == 6 &&
              move.rollSequence == 1,
        );

        engine.executeMove(moveSix);

        expect(
          engine.state.turnState.availableRolls.values,
          [4],
        );

        final moveFour =
        engine.getValidMoves()
            .whereType<MoveToken>()
            .firstWhere(
              (move) =>
          move.tokenId ==
              'player-1-token-0' &&
              move.steps == 4 &&
              move.rollSequence == 2,
        );

        engine.executeMove(moveFour);

        expect(
          engine.state.turnState.availableRolls.isEmpty,
          isTrue,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );
      },
    );

    // ==========================================================
    // 9. Turn order by seat
    // ==========================================================

    test(
      'Turn moves according to seat order',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
            createPlayer(
              playerId: 'player-3',
              seat: 3,
              color: LudoPlayerColor.blue,
            ),
          ],
        );

        expect(
          engine.currentPlayer.playerId,
          'player-1',
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final move =
        engine.getValidMoves()
            .whereType<MoveToken>()
            .firstWhere(
              (move) =>
          move.tokenId ==
              'player-1-token-0' &&
              move.steps == 4,
        );

        engine.executeMove(move);

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final moveTwo =
        engine.getValidMoves()
            .whereType<MoveToken>()
            .firstWhere(
              (move) =>
          move.tokenId ==
              'player-2-token-0' &&
              move.steps == 4,
        );

        engine.executeMove(moveTwo);

        expect(
          engine.currentPlayer.playerId,
          'player-3',
        );
      },
    );

    // ==========================================================
    // 10. First token finishes player
    // ==========================================================

    test(
      'First token reaching finish gives the player a rank',
          () {
        final greenPath = LudoPaths.green;
        final finishIndex =
            greenPath.length - 1;

        final tokenPosition =
        greenPath[finishIndex - 4];

        final playerOneTokens = <LudoToken>[
          createToken(
            playerId: 'player-1',
            tokenIndex: 0,
            state: LudoTokenState.normal,
            positionInPath: finishIndex - 4,
            position: tokenPosition,
          ),
          ...List.generate(
            3,
                (index) => createToken(
              playerId: 'player-1',
              tokenIndex: index + 1,
            ),
          ),
        ];

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              tokens: playerOneTokens,
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final finishMove =
        engine.getValidMoves()
            .whereType<MoveToken>()
            .firstWhere(
              (move) =>
          move.tokenId ==
              'player-1-token-0' &&
              move.steps == 4,
        );

        engine.executeMove(finishMove);

        expect(
          engine.state.finishedPlayerIds,
          ['player-1'],
        );

        expect(
          engine.state.getRankForPlayer(
            'player-1',
          ),
          1,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );
      },
    );
  });
}