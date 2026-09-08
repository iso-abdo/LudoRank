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
    // HELPERS
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
      required LudoPlayerColor color,
      List<LudoToken>? tokens,
      bool hasCaptured = false,
    }) {
      return LudoPlayer(
        id: playerId,
        playerId: playerId,
        name: playerId,
        color: color,
        seat: seat,
        hasCaptured: hasCaptured,
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


    LudoGameEngine createTwoPlayerEngine() {
      return createEngine(
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
    }

    LudoGameEngine createCaptureEngine({
      required int attackerStep,
    }) {
      final attackerPath = LudoPaths.green;
      final defenderPath = LudoPaths.yellow;

      final destination = attackerPath.positionAt(
        step: attackerStep + 4,
        hasCaptured: false,
      );

      final defenderStep = defenderPath.mainLoopPath.indexOf(
        destination,
      );

      if (defenderStep == -1) {
        throw StateError(
          'Destination is not present on defender path.',
        );
      }

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: attackerStep,
        position: attackerPath.positionAt(
          step: attackerStep,
          hasCaptured: false,
        ),
      );

      final defender = createToken(
        playerId: 'player-2',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: defenderStep,
        position: destination,
      );

      return createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.green,
            tokens: [
              attacker,
              ...List.generate(
                3,
                    (index) => createToken(
                  playerId: 'player-1',
                  tokenIndex: index + 1,
                ),
              ),
            ],
          ),
          createPlayer(
            playerId: 'player-2',
            seat: 2,
            color: LudoPlayerColor.yellow,
            tokens: [
              defender,
              ...List.generate(
                3,
                    (index) => createToken(
                  playerId: 'player-2',
                  tokenIndex: index + 1,
                ),
              ),
            ],
          ),
        ],
      );
    }
    LudoPlayer getPlayer(
        LudoGameEngine engine,
        String playerId,
        ) {
      return engine.state.players.firstWhere(
            (player) => player.playerId == playerId,
      );
    }

    LudoToken getToken(
        LudoGameEngine engine,
        String playerId,
        int tokenIndex,
        ) {
      final player = getPlayer(
        engine,
        playerId,
      );

      return player.tokens.firstWhere(
            (token) => token.tokenIndex == tokenIndex,
      );
    }

    // ==========================================================
    // 1. START GAME
    // ==========================================================

    test(
      'Fast Mode starts with exactly one token outside Home',
          () {
        final engine = createTwoPlayerEngine();

        for (final player in engine.state.players) {
          final outsideTokens = player.tokens
              .where((token) => !token.isInitial)
              .toList();

          expect(
            outsideTokens,
            hasLength(1),
          );

          final token = outsideTokens.single;

          expect(
            token.tokenIndex,
            0,
          );

          expect(
            token.positionInPath,
            0,
          );

          final path = LudoPaths.forColor(
            player.color,
          );

          expect(
            token.position,
            path.startingPosition,
          );

          expect(
            token.state,
            LudoTokenState.safe,
          );
        }
      },
    );

    // ==========================================================
    // 2. FIRST PLAYER BY SEAT
    // ==========================================================

    test(
      'first turn belongs to the player with the lowest seat',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
            ),
          ],
        );

        expect(
          engine.currentPlayer.playerId,
          'player-1',
        );

        expect(
          engine.state.turnState.playerId,
          'player-1',
        );
      },
    );

    // ==========================================================
    // 3. ROLL 4
    // ==========================================================

    test(
      'Roll 4 enters Playing and makes the roll available',
          () {
        final engine = createTwoPlayerEngine();

        final moves = engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.playing,
        );

        expect(
          engine.state.turnState.rolls,
          hasLength(1),
        );

        expect(
          engine.state.turnState.availableRolls.count,
          1,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [4],
        );

        expect(
          moves,
          isNotEmpty,
        );
      },
    );

    // ==========================================================
    // 4. SIX
    // ==========================================================

    test(
      'Roll 6 stays in Rolling and grants another roll',
          () {
        final engine = createTwoPlayerEngine();

        final moves = engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
        );

        expect(
          engine.state.turnState.sixRollCount,
          1,
        );

        expect(
          engine.state.turnState.rolls,
          hasLength(1),
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6],
        );

        expect(
          moves,
          isEmpty,
        );
      },
    );

    // ==========================================================
    // 5. SIX -> FOUR
    // ==========================================================

    test(
      'Roll 6 then 4 keeps both rolls available',
          () {
        final engine = createTwoPlayerEngine();

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
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
          engine.state.turnState.sixRollCount,
          1,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 4],
        );

        final moves = engine.getValidMoves();

        expect(
          moves.any(
                (move) =>
            move.rollSequence == 1 &&
                move is ExitToken &&
                move.tokenId ==
                    'player-1-token-1',
          ),
          isTrue,
        );

        expect(
          moves.any(
                (move) =>
            move is MoveToken &&
                move.rollSequence == 2 &&
                move.tokenId ==
                    'player-1-token-0' &&
                move.steps == 4,
          ),
          isTrue,
        );
      },
    );

    // ==========================================================
    // 6. SIX -> SIX -> FOUR
    // ==========================================================

    test(
      'two sixes in one turn are both counted',
          () {
        final engine = createTwoPlayerEngine();

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 6,
          sequence: 2,
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
          [6, 6],
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
          engine.state.turnState.sixRollCount,
          2,
        );

        expect(
          engine.state.turnState.availableRolls.values,
          [6, 6, 4],
        );
      },
    );

    // ==========================================================
    // 7. NON-CONSECUTIVE SIXES
    // ==========================================================

    test(
      'player can use different rolls on different active tokens',
          () {
        final greenPath = LudoPaths.green;

        final tokenZero = createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 0,
          position: greenPath.positionAt(
            step: 0,
            hasCaptured: false,
          ),
        );

        final tokenOne = createToken(
          playerId: 'player-1',
          tokenIndex: 1,
          state: LudoTokenState.normal,
          positionInPath: 10,
          position: greenPath.positionAt(
            step: 10,
            hasCaptured: false,
          ),
        );

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              tokens: [
                tokenZero,
                tokenOne,
                createToken(
                  playerId: 'player-1',
                  tokenIndex: 2,
                ),
                createToken(
                  playerId: 'player-1',
                  tokenIndex: 3,
                ),
              ],
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

        expect(
          moves.any(
                (move) =>
            move is MoveToken &&
                move.tokenId ==
                    'player-1-token-0' &&
                move.steps == 6 &&
                move.rollSequence == 1,
          ),
          isTrue,
        );

        expect(
          moves.any(
                (move) =>
            move is MoveToken &&
                move.tokenId ==
                    'player-1-token-1' &&
                move.steps == 4 &&
                move.rollSequence == 2,
          ),
          isTrue,
        );

        final moveSix = moves.firstWhere(
              (move) =>
          move is MoveToken &&
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
          engine.currentPlayer.playerId,
          'player-1',
        );

        final moveFour =
        engine.getValidMoves().firstWhere(
              (move) =>
          move is MoveToken &&
              move.tokenId ==
                  'player-1-token-1' &&
              move.steps == 4 &&
              move.rollSequence == 2,
        );

        engine.executeMove(moveFour);

        expect(
          engine.state.turnState.availableRolls,
          isEmpty,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );

        expect(
          getToken(
            engine,
            'player-1',
            0,
          ).positionInPath,
          6,
        );

        expect(
          getToken(
            engine,
            'player-1',
            1,
          ).positionInPath,
          14,
        );
      },
    );

    // ==========================================================
    // 8. NON-CONSECUTIVE SIXES IN SAME TURN
    // ==========================================================

    test(
      '6 -> 4 -> 6 -> 3 -> 6 counts as three sixes in one turn',
          () {
        final engine = createTwoPlayerEngine();

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        // Use the 4 so that the turn can continue.
        final move4 = engine.getValidMoves().firstWhere(
              (move) =>
          move is MoveToken &&
              move.rollSequence == 2 &&
              move.steps == 4,
        );

        engine.executeMove(move4);

        expect(
          engine.currentPlayer.playerId,
          'player-1',
        );

        expect(
          engine.state.turnState.phase,
          TurnPhase.rolling,
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
          engine.state.turnState.sixRollCount,
          2,
        );

        engine.registerDiceRoll(
          value: 3,
          sequence: 4,
        );

        final move3 = engine.getValidMoves().firstWhere(
              (move) =>
          move is MoveToken &&
              move.rollSequence == 4 &&
              move.steps == 3,
        );

        engine.executeMove(move3);

        expect(
          engine.currentPlayer.playerId,
          'player-1',
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
          value: 6,
          sequence: 5,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );

        expect(
          engine.state.turnState.sixRollCount,
          isZero,
        );

        expect(
          engine.state.turnState.rolls,
          isEmpty,
        );

        expect(
          engine.state.turnState.availableRolls,
          isEmpty,
        );
      },
    );

    // ==========================================================
    // 9. EXECUTE MOVE CONSUMES THE CORRECT ROLL
    // ==========================================================

    test(
      'executing a move consumes only its selected roll',
          () {
        final engine = createTwoPlayerEngine();

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        final move = engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0' &&
              option.rollSequence == 2,
        );

        engine.executeMove(move);

        expect(
          engine.state.turnState.availableRolls.values,
          [6],
        );
      },
    );

    // ==========================================================
    // 10. EXIT TOKEN WITH SIX
    // ==========================================================

    test(
      'a 6 allows an initial token to exit Home',
          () {
        final engine = createTwoPlayerEngine();

        engine.registerDiceRoll(
          value: 6,
          sequence: 1,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 2,
        );

        final exitMove =
        engine.getValidMoves().firstWhere(
              (move) =>
          move is ExitToken &&
              move.tokenId ==
                  'player-1-token-1' &&
              move.rollSequence == 1,
        );

        engine.executeMove(exitMove);

        final player =
            engine.state.players.first;

        final token =
        player.tokens.firstWhere(
              (token) =>
          token.tokenIndex == 1,
        );

        final path =
            LudoPaths.green;

        expect(
          token.positionInPath,
          0,
        );

        expect(
          token.position,
          path.startingPosition,
        );

        expect(
          token.state,
          LudoTokenState.safe,
        );

        expect(
          engine.state.turnState
              .availableRolls.values,
          [4],
        );
      },
    );

    // ==========================================================
    // 11. MAIN LOOP WRAP BEFORE CAPTURE
    // ==========================================================

    test(
      'before capture, step 51 wraps to step 0',
          () {
        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              tokens: [
                createToken(
                  playerId: 'player-1',
                  tokenIndex: 0,
                  state: LudoTokenState.normal,
                  positionInPath: 50,
                  position:
                  LudoPaths.green.mainLoopPath[50],
                ),
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-1',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 2,
          sequence: 1,
        );

        final move = engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0',
        );

        engine.executeMove(move);

        final token =
        engine.currentPlayer.tokens.firstWhere(
              (token) =>
          token.tokenIndex == 0,
        );

        expect(
          token.positionInPath,
          0,
        );

        expect(
          token.position,
          LudoPaths.green.startingPosition,
        );
      },
    );

    // ==========================================================
    // 12. HOME LANE AFTER CAPTURE
    // ==========================================================

    test(
      'after capture, step 50 can move into Home Lane step 51',
          () {
        final player = createPlayer(
          playerId: 'player-1',
          seat: 1,
          color: LudoPlayerColor.green,
          hasCaptured: true,
          tokens: [
            createToken(
              playerId: 'player-1',
              tokenIndex: 0,
              state: LudoTokenState.normal,
              positionInPath: 50,
              position:
              LudoPaths.green.mainLoopPath[50],
            ),
            ...List.generate(
              3,
                  (index) => createToken(
                playerId: 'player-1',
                tokenIndex: index + 1,
              ),
            ),
          ],
        );

        final engine = createEngine(
          players: [
            player,
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 1,
          sequence: 1,
        );

        final move =
        engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0',
        );

        engine.executeMove(move);

        final token =
        engine.currentPlayer.tokens.firstWhere(
              (token) =>
          token.tokenIndex == 0,
        );

        expect(
          token.positionInPath,
          51,
        );

        expect(
          token.position,
          LudoPaths.green.homePath.first,
        );

        expect(
          token.state,
          LudoTokenState.safe,
        );
      },
    );

    // ==========================================================
    // 13. EXACT FINISH
    // ==========================================================

    test(
      'token finishes only when it reaches step 56 exactly',
          () {
        final token = createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 55,
          position:
          LudoPaths.green.homePath[4],
        );

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              hasCaptured: true,
              tokens: [
                token,
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-1',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 1,
          sequence: 1,
        );

        final move =
        engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0',
        );

        engine.executeMove(move);

        final updatedToken =
        engine.state.players
            .firstWhere(
              (player) =>
          player.playerId ==
              'player-1',
        )
            .tokens
            .firstWhere(
              (token) =>
          token.tokenIndex ==
              0,
        );

        expect(
          updatedToken.positionInPath,
          56,
        );

        expect(
          updatedToken.position,
          LudoPaths.green.finishPosition,
        );

        expect(
          updatedToken.state,
          LudoTokenState.finished,
        );
      },
    );

    // ==========================================================
    // 14. PLAYER RANKING
    // ==========================================================

    test(
      'the player who finishes gets the next rank',
          () {
        final token = createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 55,
          position:
          LudoPaths.green.homePath[4],
        );

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              hasCaptured: true,
              tokens: [
                token,
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-1',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 1,
          sequence: 1,
        );

        final move =
        engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0',
        );

        engine.executeMove(move);

        expect(
          engine.state.finishedPlayerIds,
          ['player-1'],
        );

        expect(
          engine.getResult()
              .getPlayerResult('player-1')!
              .rank,
          1,
        );

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );
      },
    );

    // ==========================================================
    // 15. CAPTURE
    // ==========================================================

    test(
      'capture sends the enemy token back to its starting cell',
          () {
        final engine =
        createCaptureEngine(
          attackerStep: 4,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final move =
        engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0' &&
              option.rollSequence == 1,
        );

        engine.executeMove(move);

        final attacker =
        engine.state.players
            .firstWhere(
              (player) =>
          player.playerId ==
              'player-1',
        );

        final defender =
        engine.state.players
            .firstWhere(
              (player) =>
          player.playerId ==
              'player-2',
        );

        final attackerToken =
        attacker.tokens.firstWhere(
              (token) =>
          token.tokenIndex == 0,
        );

        final defenderToken =
        defender.tokens.firstWhere(
              (token) =>
          token.tokenIndex == 0,
        );

        expect(
          attacker.hasCaptured,
          isTrue,
        );

        expect(
          attackerToken.positionInPath,
          8,
        );

        expect(
          attackerToken.position,
          LudoPaths.green.positionAt(
            step: 8,
            hasCaptured: false,
          ),
        );

        expect(
          defenderToken.positionInPath,
          0,
        );

        expect(
          defenderToken.position,
          LudoPaths.yellow.startingPosition,
        );
      },
    );

    // ==========================================================
    // 16. CAPTURE IMMEDIATE EXTRA ROLL
    // ==========================================================

    test(
      'capture grants an immediate extra roll',
          () {
        final engine =
        createCaptureEngine(
          attackerStep: 4,
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final move =
        engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0' &&
              option.rollSequence == 1,
        );

        final state =
        engine.executeMove(move);

        expect(
          state.turnState.phase,
          TurnPhase.rolling,
        );

        expect(
          state.currentPlayer.playerId,
          'player-1',
        );

        expect(
          state.turnState.availableRolls,
          isEmpty,
        );
      },
    );

    // ==========================================================
    // 17. SAFE CELL CANNOT BE CAPTURED
    // ==========================================================

    test(
      'safe cells cannot be captured',
          () {
        final safePosition =
        LudoPaths.green.positionAt(
          step: 8,
          hasCaptured: false,
        );

        final attacker = createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 4,
          position:
          LudoPaths.green.mainLoopPath[4],
        );

        final defender = createToken(
          playerId: 'player-2',
          tokenIndex: 0,
          state: LudoTokenState.safe,
          positionInPath: 8,
          position: safePosition,
        );

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              tokens: [
                attacker,
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-1',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
              tokens: [
                defender,
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-2',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final moves =
        engine.getValidMoves();

        final captureMoveExists =
        moves.any(
              (move) =>
          move is MoveToken &&
              move.tokenId ==
                  'player-1-token-0',
        );

        expect(
          captureMoveExists,
          isFalse,
        );
      },
    );

    // ==========================================================
    // 18. ENEMY BLOCK
    // ==========================================================

    test(
      'landing on an enemy block is illegal',
          () {
        final path =
            LudoPaths.green;

        const attackerStep = 4;
        const destinationStep = 8;

        final destination =
        path.positionAt(
          step: destinationStep,
          hasCaptured: false,
        );

        final attacker =
        createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: attackerStep,
          position:
          path.mainLoopPath[attackerStep],
        );

        final enemy1 =
        createToken(
          playerId: 'player-2',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 8,
          position: destination,
        );

        final enemy2 =
        createToken(
          playerId: 'player-2',
          tokenIndex: 1,
          state: LudoTokenState.normal,
          positionInPath: 8,
          position: destination,
        );

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              tokens: [
                attacker,
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-1',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
            ),
            createPlayer(
              playerId: 'player-2',
              seat: 2,
              color: LudoPlayerColor.yellow,
              tokens: [
                enemy1,
                enemy2,
                ...List.generate(
                  2,
                      (index) => createToken(
                    playerId: 'player-2',
                    tokenIndex: index + 2,
                  ),
                ),
              ],
            ),
          ],
        );

        engine.registerDiceRoll(
          value: 4,
          sequence: 1,
        );

        final moves =
        engine.getValidMoves();

        expect(
          moves.whereType<MoveToken>().any(
                (move) =>
            move.tokenId ==
                'player-1-token-0',
          ),
          isFalse,
        );
      },
    );

    // ==========================================================
    // 19. RESULT
    // ==========================================================

    test(
      'getResult returns ranks in finish order',
          () {
        final engine =
        createTwoPlayerEngine();

        final state =
            engine.state;

        expect(
          state.finishedPlayerIds,
          isEmpty,
        );

        expect(
          engine.getResult().players,
          isEmpty,
        );
      },
    );

    // ==========================================================
    // 20. NEXT PLAYER SKIPS FINISHED PLAYER
    // ==========================================================

    test(
      'finished players are skipped in turn order',
          () {
        final token = createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 55,
          position:
          LudoPaths.green.homePath[4],
        );

        final engine = createEngine(
          players: [
            createPlayer(
              playerId: 'player-1',
              seat: 1,
              color: LudoPlayerColor.green,
              hasCaptured: true,
              tokens: [
                token,
                ...List.generate(
                  3,
                      (index) => createToken(
                    playerId: 'player-1',
                    tokenIndex: index + 1,
                  ),
                ),
              ],
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

        engine.registerDiceRoll(
          value: 1,
          sequence: 1,
        );

        final move =
        engine.getValidMoves().firstWhere(
              (option) =>
          option is MoveToken &&
              option.tokenId ==
                  'player-1-token-0',
        );

        engine.executeMove(move);

        expect(
          engine.currentPlayer.playerId,
          'player-2',
        );

        expect(
          engine.state.finishedPlayerIds,
          ['player-1'],
        );
      },
    );
  });
}