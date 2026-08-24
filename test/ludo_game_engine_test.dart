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
      'Roll 4 gives valid moves for the current player',
          () {
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
        );

        final moves = engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        expect(
          engine.state.turnState.isPlaying,
          isTrue,
        );

        expect(
          engine.state.turnState.rolls.length,
          1,
        );

        expect(
          engine.state.turnState.availableRolls.count,
          1,
        );

        final validMoves =
        engine.getValidMoves();

        expect(
          validMoves,
          isNotEmpty,
        );

        expect(
          validMoves.whereType<MoveToken>().any(
                (move) =>
            move.tokenId ==
                'player-1-token-0' &&
                move.steps == 4 &&
                move.rollSequence == 1,
          ),
          isTrue,
        );

        // registerDiceRoll itself now returns state.
        expect(
          moves,
          isNotNull,
        );
      },
    );

    // ==========================================================
    // 2. Roll 6 -> Roll 4
    // ==========================================================

    test(
      'Roll 6 then Roll 4 keeps both rolls available',
          () {
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
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
          engine.state.turnState.rolls.length,
          1,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6],
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
          engine.state.turnState.rolls.length,
          2,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 4],
        );

        final moves =
        engine.getValidMoves();

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
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
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
          engine.state.turnState.consecutiveSixes,
          2,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
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
              .map((roll) => roll.value),
          [6, 6, 4],
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 6, 4],
        );

        expect(
          engine.getValidMoves(),
          isNotEmpty,
        );
      },
    );

    // ==========================================================
    // 4. Roll 6 -> Roll 6 -> Roll 6
    // ==========================================================

    test(
      'Three consecutive sixes cancel the turn and move to next player',
          () {
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
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
          engine.state.turnState.consecutiveSixes,
          0,
        );
      },
    );

    // ==========================================================
    // 5. Player can choose more than one token
    // ==========================================================

    test(
      'Player can use different rolls on different tokens',
          () {
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        final moves =
        engine.getValidMoves();

        final tokenZeroSixMove =
        moves.whereType<MoveToken>().firstWhere(
              (move) =>
          move.tokenId ==
              'player-1-token-0' &&
              move.steps == 6,
        );

        engine.executeMove(
          tokenZeroSixMove,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [4],
        );

        final tokenZero =
        engine.state.currentPlayer.tokens
            .firstWhere(
              (token) =>
          token.tokenIndex == 0,
        );

        expect(
          tokenZero.positionInPath,
          6,
        );

        // The second roll can now be used
        // independently.
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
    // 6. Consume rolls one by one
    // ==========================================================

    test(
      'Available rolls are consumed one by one',
          () {
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
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
        engine
            .getValidMoves()
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
        engine
            .getValidMoves()
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
    // 7. Turn moves to next player
    // ==========================================================

    test(
      'Turn moves according to seat order',
          () {
        final players = [
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
        ];

        final engine = createEngine(
          players: players,
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
        engine
            .getValidMoves()
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
        engine
            .getValidMoves()
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
    // 8. Player finishes with first token
    // ==========================================================

    test(
      'Player gets rank when the first token reaches finish',
          () {
        final playerOneTokens =
        <LudoToken>[];

        final greenPath = LudoPaths.green;

        final finishIndex =
            greenPath.length - 1;

        final startPosition =
        greenPath[finishIndex - 4];

        // Token 0 is four steps away from finish.
        playerOneTokens.add(
          createToken(
            playerId: 'player-1',
            tokenIndex: 0,
            state: LudoTokenState.normal,
            positionInPath: finishIndex - 4,
            position: startPosition,
          ),
        );

        // Remaining tokens stay in initial state.
        for (var index = 1; index < 4; index++) {
          playerOneTokens.add(
            createToken(
              playerId: 'player-1',
              tokenIndex: index,
            ),
          );
        }

        final players = [
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
        ];

        final engine = createEngine(
          players: players,
        );

        // The player starts with token 0
        // already on the board.
        final moves = engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        expect(
          moves,
          isNotNull,
        );

        final finishMove =
        engine
            .getValidMoves()
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
          engine.state.currentPlayer.playerId,
          'player-2',
        );
      },
    );
  });
}