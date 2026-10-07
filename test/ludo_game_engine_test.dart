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
  group('LudoGameEngine - Rule Audit', () {
    LudoToken createToken({
      required String playerId,
      required int tokenIndex,
      LudoTokenState state = LudoTokenState.initial,
      int positionInPath = -1,
      Position? position,
      bool hasCaptured = false,
      bool homeEntryPending = false,
    }) {
      return LudoToken(
        id: '$playerId-token-$tokenIndex',
        playerId: playerId,
        tokenIndex: tokenIndex,
        position: position ?? const Position(row: 0, column: 0),
        positionInPath: positionInPath,
        state: state,
        homeEntryPending: homeEntryPending,
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
        tokens:
            tokens ??
            List.generate(
              4,
              (index) => createToken(playerId: playerId, tokenIndex: index),
            ),
      );
    }

    LudoGameEngine createEngine({required List<LudoPlayer> players}) {
      final engine = LudoGameEngine(
        initialState: LudoGameState.initial(players: players),
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

    LudoToken getToken(LudoGameEngine engine, String playerId, int tokenIndex) {
      final player = engine.state.players.firstWhere(
        (item) => item.playerId == playerId,
      );

      return player.tokens.firstWhere((item) => item.tokenIndex == tokenIndex);
    }

    LudoGameEngine createCaptureEngine({required int attackerStep}) {
      final attackerPath = LudoPaths.green;
      final defenderPath = LudoPaths.yellow;
      final destination = attackerPath.positionAt(
        step: attackerStep + 4,
        useHomeLane: false,
      );
      final defenderStep = defenderPath.mainLoopPath.indexOf(destination);

      if (defenderStep == -1) {
        throw StateError('Destination is not present on defender path.');
      }

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: attackerStep,
        position: attackerPath.positionAt(
          step: attackerStep,
          useHomeLane: false,
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
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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
                (index) =>
                    createToken(playerId: 'player-2', tokenIndex: index + 1),
              ),
            ],
          ),
        ],
      );
    }

    LudoGameEngine createFinishingEngine() {
      final greenFinisher = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: LudoPath.finishStep - 1,
        position: LudoPaths.green.homePath[4],
      );

      final yellowFinisher = createToken(
        playerId: 'player-2',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: LudoPath.finishStep - 1,
        position: LudoPaths.yellow.homePath[4],
      );

      return createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.green,
            hasCaptured: true,
            tokens: [
              greenFinisher,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
              ),
            ],
          ),
          createPlayer(
            playerId: 'player-2',
            seat: 2,
            color: LudoPlayerColor.yellow,
            hasCaptured: true,
            tokens: [
              yellowFinisher,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-2', tokenIndex: index + 1),
              ),
            ],
          ),
        ],
      );
    }

    LudoGameEngine createStep51CaptureEngine() {
      final attackerPath = LudoPaths.green;
      final defenderPath = LudoPaths.yellow;

      final destination = attackerPath.mainLoopPath[51];
      final defenderStep = defenderPath.mainLoopPath.indexOf(destination);

      if (defenderStep == -1) {
        throw StateError(
          'Step 51 physical position is not on the defender path.',
        );
      }

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: 50,
        position: attackerPath.mainLoopPath[50],
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
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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
                (index) =>
                    createToken(playerId: 'player-2', tokenIndex: index + 1),
              ),
            ],
          ),
        ],
      );
    }

    LudoGameEngine createStep51DefenderEngine() {
      final attackerPath = LudoPaths.yellow;
      final defenderPath = LudoPaths.green;

      final destination = defenderPath.mainLoopPath[51];
      final attackerStep = attackerPath.mainLoopPath.indexOf(destination) - 1;

      if (attackerStep < 0) {
        throw StateError(
          'Could not determine attacker step for Step 51 capture.',
        );
      }

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: attackerStep,
        position: attackerPath.mainLoopPath[attackerStep],
      );

      final defender = createToken(
        playerId: 'player-2',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: 51,
        position: destination,
      );

      return createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.yellow,
            tokens: [
              attacker,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
              ),
            ],
          ),
          createPlayer(
            playerId: 'player-2',
            seat: 2,
            color: LudoPlayerColor.green,
            tokens: [
              defender,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-2', tokenIndex: index + 1),
              ),
            ],
          ),
        ],
      );
    }
    // ==========================================================
    // ==========================================================
    // STEP 51 PATH SEMANTICS
    // ==========================================================

    test('Step 51 is Main Loop when Home Lane is not active', () {
      final path = LudoPaths.green;

      expect(
        path.positionAt(step: LudoPath.lastMainLoopStep, useHomeLane: false),
        path.mainLoopPath[51],
      );

      expect(
        path.nextStep(
          currentStep: LudoPath.lastMainLoopStep,
          useHomeLane: false,
        ),
        0,
      );
    });

    test('Step 51 is Home Lane when Home Lane is active', () {
      final path = LudoPaths.green;

      expect(
        path.positionAt(step: LudoPath.homeLaneStartStep, useHomeLane: true),
        path.homePath[0],
      );

      expect(
        path.nextStep(
          currentStep: LudoPath.lastMainLoopStep,
          useHomeLane: true,
        ),
        52,
      );
    });
    // Test: أقدر أقف على Step 51
    test('Step 51 is a normal playable Main Loop cell before capture', () {
      final path = LudoPaths.green;

      final token = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: 50,
        position: path.mainLoopPath[50],
      );

      final engine = createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.green,
            tokens: [
              token,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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

      engine.registerDiceRoll(value: 1, sequence: 1);

      final move = engine.getValidMoves().firstWhere(
        (option) =>
            option is MoveToken &&
            option.tokenId == 'player-1-token-0' &&
            option.rollSequence == 1,
      );

      engine.executeMove(move);

      final updated = getToken(engine, 'player-1', 0);

      expect(updated.positionInPath, 51);
      expect(updated.position, path.mainLoopPath[51]);
      expect(updated.state, LudoTokenState.normal);
      expect(updated.homeEntryPending, isFalse);
    });
    //Test: أقدر آكل على 51
    test('A Token can capture an enemy Token on Main Loop Step 51', () {
      final engine = createStep51CaptureEngine();

      engine.registerDiceRoll(value: 1, sequence: 1);

      final move = engine.getValidMoves().firstWhere(
        (option) =>
            option is MoveToken &&
            option.tokenId == 'player-1-token-0' &&
            option.rollSequence == 1,
      );

      engine.executeMove(move);

      final attacker = getToken(engine, 'player-1', 0);

      final defender = getToken(engine, 'player-2', 0);

      final attackerPlayer = engine.state.players.firstWhere(
        (player) => player.playerId == 'player-1',
      );

      expect(attacker.positionInPath, 51);
      expect(attacker.position, LudoPaths.green.mainLoopPath[51]);

      expect(attackerPlayer.hasCaptured, isTrue);
      expect(attacker.homeEntryPending, isTrue);

      expect(defender.positionInPath, -1);
      expect(defender.position, const Position(row: 0, column: 0));
      expect(defender.state, LudoTokenState.initial);
      expect(defender.homeEntryPending, isFalse);
    });
    // Test: ممكن أتآكل وأنا واقف على 51
    test('A Token standing on Main Loop Step 51 can be captured', () {
      final engine = createStep51DefenderEngine();

      engine.registerDiceRoll(value: 1, sequence: 1);

      final move = engine.getValidMoves().firstWhere(
        (option) =>
            option is MoveToken &&
            option.tokenId == 'player-1-token-0' &&
            option.rollSequence == 1,
      );

      engine.executeMove(move);

      final attacker = getToken(engine, 'player-1', 0);

      final defender = getToken(engine, 'player-2', 0);

      expect(attacker.position, LudoPaths.yellow.mainLoopPath[38]);

      expect(defender.positionInPath, -1);

      expect(defender.position, const Position(row: 0, column: 0));

      expect(defender.state, LudoTokenState.initial);
    });
    // أهم Test: الـ Token الذي أكل على 51 يكمل الدورة
    test(
      'Token that captured on Step 51 completes one full lap before entering Home Lane',
      () {
        final token = createToken(
          playerId: 'player-1',
          tokenIndex: 0,
          state: LudoTokenState.normal,
          positionInPath: 51,
          position: LudoPaths.green.mainLoopPath[51],
          homeEntryPending: true,
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
                  (index) =>
                      createToken(playerId: 'player-1', tokenIndex: index + 1),
                ),
              ],
            ),
          ],
        );

        // 51 -> 0
        engine.registerDiceRoll(value: 1, sequence: 1);

        var move = engine.getValidMoves().firstWhere(
          (option) =>
              option is MoveToken && option.tokenId == 'player-1-token-0',
        );

        engine.executeMove(move);

        var updated = getToken(engine, 'player-1', 0);

        expect(updated.positionInPath, 0);
        expect(updated.position, LudoPaths.green.mainLoopPath[0]);
        expect(updated.homeEntryPending, isTrue);

        // 0 -> 1 -> ... -> 50
        for (var expectedStep = 1; expectedStep <= 50; expectedStep++) {
          engine.registerDiceRoll(value: 1, sequence: 1);

          move = engine.getValidMoves().firstWhere(
            (option) =>
                option is MoveToken && option.tokenId == 'player-1-token-0',
          );

          engine.executeMove(move);

          updated = getToken(engine, 'player-1', 0);

          expect(updated.positionInPath, expectedStep);
          expect(updated.homeEntryPending, isTrue);
        }

        // 50 -> 51(Home Lane)
        engine.registerDiceRoll(value: 1, sequence: 1);

        move = engine.getValidMoves().firstWhere(
          (option) =>
              option is MoveToken && option.tokenId == 'player-1-token-0',
        );

        engine.executeMove(move);

        updated = getToken(engine, 'player-1', 0);

        expect(updated.positionInPath, LudoPath.homeLaneStartStep);

        expect(updated.position, LudoPaths.green.homePath[0]);

        expect(updated.homeEntryPending, isFalse);
      },
    );

    // ==========================================================
    // 1. HOME LANE LOCK

    test('Home Lane is locked before the first capture', () {
      final token = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: 50,
        position: LudoPaths.green.mainLoopPath[50],
      );

      final engine = createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.green,
            hasCaptured: false,
            tokens: [
              token,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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

      engine.registerDiceRoll(value: 2, sequence: 1);
      final move = engine.getValidMoves().firstWhere(
        (option) =>
            option is MoveToken &&
            option.tokenId == 'player-1-token-0' &&
            option.steps == 2,
      );

      engine.executeMove(move);

      final updated = getToken(engine, 'player-1', 0);

      // Before the first capture, step 51 is still the last main-loop
      // position. The token must wrap to step 0 instead of entering
      // the Home Lane.
      expect(updated.positionInPath, 0);
      expect(updated.position, LudoPaths.green.startingPosition);
      expect(updated.state, isNot(LudoTokenState.finished));
    });

    // ==========================================================
    // 2. EXACT FINISH + OVERSHOOT
    // ==========================================================

    test('Exact Finish is legal and Overshoot is illegal', () {
      final exactFinishToken = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: 55,
        position: LudoPaths.green.homePath[4],
      );

      final exactEngine = createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.green,
            hasCaptured: true,
            tokens: [
              exactFinishToken,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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

      exactEngine.registerDiceRoll(value: 1, sequence: 1);
      final finishMove = exactEngine.getValidMoves().firstWhere(
        (option) => option is MoveToken && option.tokenId == 'player-1-token-0',
      );
      exactEngine.executeMove(finishMove);

      final finishedToken = getToken(exactEngine, 'player-1', 0);

      expect(finishedToken.positionInPath, LudoPath.finishStep);
      expect(finishedToken.state, LudoTokenState.finished);

      final overshootToken = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: 54,
        position: LudoPaths.green.homePath[3],
      );

      final overshootEngine = createEngine(
        players: [
          createPlayer(
            playerId: 'player-1',
            seat: 1,
            color: LudoPlayerColor.green,
            hasCaptured: true,
            tokens: [
              overshootToken,
              ...List.generate(
                3,
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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

      overshootEngine.registerDiceRoll(value: 3, sequence: 1);

      expect(overshootEngine.getValidMoves().whereType<MoveToken>(), isEmpty);
    });

    // ==========================================================
    // 3. PASSING OVER BLOCK
    // ==========================================================

    test('Passing over an enemy block is legal', () {
      final path = LudoPaths.green;
      const attackerStep = 5;
      const blockStep = 7;
      const destinationStep = 9;
      final blockPosition = path.positionAt(
        step: blockStep,
        useHomeLane: false,
      );

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: attackerStep,
        position: path.mainLoopPath[attackerStep],
      );

      final enemy1 = createToken(
        playerId: 'player-2',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: blockStep,
        position: blockPosition,
      );

      final enemy2 = createToken(
        playerId: 'player-2',
        tokenIndex: 1,
        state: LudoTokenState.normal,
        positionInPath: blockStep,
        position: blockPosition,
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
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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
                (index) =>
                    createToken(playerId: 'player-2', tokenIndex: index + 2),
              ),
            ],
          ),
        ],
      );

      engine.registerDiceRoll(value: 4, sequence: 1);

      expect(
        engine.getValidMoves().any(
          (option) =>
              option is MoveToken &&
              option.tokenId == 'player-1-token-0' &&
              option.steps == 4,
        ),
        isTrue,
      );

      expect(destinationStep, 9);
    });

    // ==========================================================
    // 4. OWN BLOCK
    // ==========================================================

    test('Own block makes the destination illegal', () {
      final path = LudoPaths.green;
      const attackerStep = 5;
      const destinationStep = 9;
      final destination = path.positionAt(
        step: destinationStep,
        useHomeLane: false,
      );

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: attackerStep,
        position: path.mainLoopPath[attackerStep],
      );

      final own1 = createToken(
        playerId: 'player-1',
        tokenIndex: 1,
        state: LudoTokenState.normal,
        positionInPath: destinationStep,
        position: destination,
      );

      final own2 = createToken(
        playerId: 'player-1',
        tokenIndex: 2,
        state: LudoTokenState.normal,
        positionInPath: destinationStep,
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
              own1,
              own2,
              createToken(playerId: 'player-1', tokenIndex: 3),
            ],
          ),
          createPlayer(
            playerId: 'player-2',
            seat: 2,
            color: LudoPlayerColor.yellow,
          ),
        ],
      );

      engine.registerDiceRoll(value: 4, sequence: 1);

      expect(
        engine.getValidMoves().whereType<MoveToken>().any(
          (option) => option.tokenId == 'player-1-token-0',
        ),
        isFalse,
      );
    });

    // ==========================================================
    // 5. OWN STACK
    // ==========================================================

    test('Own stack with one token is a legal destination', () {
      final path = LudoPaths.green;
      const attackerStep = 5;
      const destinationStep = 9;
      final destination = path.positionAt(
        step: destinationStep,
        useHomeLane: false,
      );

      final attacker = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.normal,
        positionInPath: attackerStep,
        position: path.mainLoopPath[attackerStep],
      );

      final ownToken = createToken(
        playerId: 'player-1',
        tokenIndex: 1,
        state: LudoTokenState.normal,
        positionInPath: destinationStep,
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
              ownToken,
              createToken(playerId: 'player-1', tokenIndex: 2),
              createToken(playerId: 'player-1', tokenIndex: 3),
            ],
          ),
          createPlayer(
            playerId: 'player-2',
            seat: 2,
            color: LudoPlayerColor.yellow,
          ),
        ],
      );

      engine.registerDiceRoll(value: 4, sequence: 1);

      final move = engine.getValidMoves().firstWhere(
        (option) =>
            option is MoveToken &&
            option.tokenId == 'player-1-token-0' &&
            option.steps == 4,
      );

      engine.executeMove(move);

      expect(getToken(engine, 'player-1', 0).positionInPath, destinationStep);
      expect(getToken(engine, 'player-1', 0).position, destination);
    });

    //
    // ==========================================================
    // 6. SINGLE ENEMY CAPTURE
    // ==========================================================

    test('Single enemy token is captured on an ordinary cell', () {
      final engine = createCaptureEngine(attackerStep: 5);

      engine.registerDiceRoll(value: 4, sequence: 1);

      final move = engine.getValidMoves().firstWhere(
        (option) =>
            option is MoveToken &&
            option.tokenId == 'player-1-token-0' &&
            option.rollSequence == 1,
      );

      engine.executeMove(move);

      final attacker = engine.state.players.firstWhere(
        (player) => player.playerId == 'player-1',
      );
      final defender = engine.state.players.firstWhere(
        (player) => player.playerId == 'player-2',
      );

      final attackerToken = attacker.tokens.firstWhere(
        (token) => token.tokenIndex == 0,
      );
      final defenderToken = defender.tokens.firstWhere(
        (token) => token.tokenIndex == 0,
      );

      expect(attacker.hasCaptured, isTrue);
      expect(attackerToken.positionInPath, 9);
      //    expect(defenderToken.positionInPath, -1);
      //  expect(
      //  defenderToken.position,
      //  const Position(row: 0, column: 0)
      //  LudoPaths.yellow.startingPosition,
      //);
      expect(defenderToken.positionInPath, -1);

      expect(defenderToken.position, const Position(row: 0, column: 0));

      expect(defenderToken.state, LudoTokenState.initial);

      expect(defenderToken.homeEntryPending, isFalse);
    });

    // ==========================================================
    // 7. TRIPLE SIX FULL CANCELLATION
    // ==========================================================
    test('Third six fully cancels the current turn', () {
      final engine = createTwoPlayerEngine();

      // ==========================================================
      // FIRST SIX
      // ==========================================================

      engine.registerDiceRoll(value: 6, sequence: 1);

      expect(engine.currentPlayer.playerId, 'player-1');

      expect(engine.state.turnState.phase, TurnPhase.rolling);

      expect(engine.state.turnState.sixRollCount, 1);

      // ==========================================================
      // SECOND SIX
      // ==========================================================

      engine.registerDiceRoll(value: 6, sequence: 2);

      expect(engine.currentPlayer.playerId, 'player-1');

      expect(engine.state.turnState.phase, TurnPhase.rolling);

      expect(engine.state.turnState.sixRollCount, 2);

      // ==========================================================
      // THIRD SIX
      // ==========================================================

      engine.registerDiceRoll(value: 6, sequence: 3);

      // Third six cancels the entire turn
      // and moves to the next unfinished player.
      expect(engine.currentPlayer.playerId, 'player-2');

      expect(engine.state.turnState.sixRollCount, 0);

      expect(engine.state.turnState.rolls, isEmpty);

      expect(engine.state.turnState.availableRolls, isEmpty);

      expect(engine.state.turnState.phase, TurnPhase.rolling);
    });

    // ==========================================================
    // 8. NO LEGAL MOVE -> AUTO END TURN
    // ==========================================================

    test('No legal move automatically ends the turn', () {
      final token = createToken(
        playerId: 'player-1',
        tokenIndex: 0,
        state: LudoTokenState.safe,
        positionInPath: 53,
        position: LudoPaths.green.homePath[2],
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
                (index) =>
                    createToken(playerId: 'player-1', tokenIndex: index + 1),
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

      final moves = engine.registerDiceRoll(value: 4, sequence: 1);

      expect(moves, isEmpty);
      expect(engine.currentPlayer.playerId, 'player-2');
      expect(engine.state.turnState.phase, TurnPhase.rolling);
      expect(engine.state.turnState.rolls, isEmpty);
      expect(engine.state.turnState.availableRolls, isEmpty);
    });

    // ==========================================================
    // 9. INVALID DICE / SEQUENCE
    // ==========================================================

    test('Invalid dice value and sequence are rejected', () {
      final engine = createTwoPlayerEngine();

      expect(
        () => engine.registerDiceRoll(value: 0, sequence: 1),
        throwsArgumentError,
      );

      expect(
        () => engine.registerDiceRoll(value: 7, sequence: 1),
        throwsArgumentError,
      );

      engine.registerDiceRoll(value: 6, sequence: 1);

      expect(
        () => engine.registerDiceRoll(value: 6, sequence: 3),
        throwsArgumentError,
      );
    });

    // ==========================================================
    // 10. ILLEGAL MOVE REJECTION
    // ==========================================================

    test('Illegal move is rejected', () {
      final engine = createTwoPlayerEngine();

      engine.registerDiceRoll(value: 4, sequence: 1);

      final illegalMove = MoveToken(
        tokenId: 'player-1-token-0',
        steps: 3,
        rollSequence: 1,
      );

      expect(() => engine.executeMove(illegalMove), throwsStateError);

      expect(engine.state.turnState.availableRolls.values, [4]);
      expect(engine.currentPlayer.playerId, 'player-1');
    });

    // ==========================================================
    // 11. ALL PLAYERS FINISHED -> GAME COMPLETED
    // ==========================================================

    test('All players finished marks the game as completed', () {
      final engine = createFinishingEngine();

      engine.registerDiceRoll(value: 1, sequence: 1);
      final firstMove = engine.getValidMoves().firstWhere(
        (option) => option is MoveToken && option.tokenId == 'player-1-token-0',
      );
      engine.executeMove(firstMove);

      expect(engine.isFinished, isFalse);
      expect(engine.currentPlayer.playerId, 'player-2');
      expect(engine.state.finishedPlayerIds, ['player-1']);

      engine.registerDiceRoll(value: 1, sequence: 1);
      final secondMove = engine.getValidMoves().firstWhere(
        (option) => option is MoveToken && option.tokenId == 'player-2-token-0',
      );
      engine.executeMove(secondMove);

      expect(engine.isFinished, isTrue);
      expect(engine.state.turnState.phase, TurnPhase.completed);
      expect(engine.state.finishedPlayerIds, ['player-1', 'player-2']);
    });

    // ==========================================================
    // 12. FINAL GAME RESULT
    // ==========================================================

    test('Final GameResult matches finish order and completion state', () {
      final engine = createFinishingEngine();

      engine.registerDiceRoll(value: 1, sequence: 1);
      final firstMove = engine.getValidMoves().firstWhere(
        (option) => option is MoveToken && option.tokenId == 'player-1-token-0',
      );
      engine.executeMove(firstMove);

      engine.registerDiceRoll(value: 1, sequence: 1);
      final secondMove = engine.getValidMoves().firstWhere(
        (option) => option is MoveToken && option.tokenId == 'player-2-token-0',
      );
      engine.executeMove(secondMove);

      final result = engine.getResult();

      expect(result.isFinished, isTrue);
      expect(result.players, hasLength(2));

      final first = result.getPlayerResult('player-1');
      final second = result.getPlayerResult('player-2');

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.rank, 1);
      expect(first.finished, isTrue);
      expect(second!.rank, 2);
      expect(second.finished, isTrue);
      expect(result.rankedPlayersCount, 2);
    });
  });
}
