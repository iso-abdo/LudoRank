import 'dart:math';

import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';
import 'package:ludo_rank/features/ludo_game/domain/constants/safe_cells.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/dice_roll.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

class LudoGameEngine {
  LudoGameState _state;

  final Random _random;

  LudoGameEngine({
    required LudoGameState initialState,
    Random? random,
  })  : _state = initialState,
        _random = random ?? Random();

  // ============================================================
  // GETTERS
  // ============================================================

  LudoGameState get state => _state;

  LudoPlayer get currentPlayer => _state.currentPlayer;

  bool get isStarted => _state.isStarted;

  bool get isFinished => _state.isFinished;

  // ============================================================
  // GAME START
  // ============================================================

  /// بدء المباراة في Fast Mode.
  ///
  /// كل لاعب يبدأ بـ Token واحد خارج البيت.
  LudoGameState startGame() {
    if (_state.isStarted) {
      return _state;
    }

    final players = _state.players
        .map(_prepareFastModePlayer)
        .toList();

    if (players.isEmpty) {
      throw StateError(
        'لا يمكن بدء اللعبة بدون لاعبين.',
      );
    }

    final firstPlayer = players.first;

    _state = _state.copyWith(
      players: players,
      currentPlayerIndex: 0,
      turnState: TurnState.initial(
        firstPlayer.playerId,
      ),
      isStarted: true,
      isFinished: false,
      finishedPlayerIds: const [],
    );

    return _state;
  }

  // ============================================================
  // TURN
  // ============================================================

  LudoGameState startTurn() {
    if (!_state.isStarted || _state.isFinished) {
      return _state;
    }

    final player = _state.currentPlayer;

    if (_state.finishedPlayerIds.contains(
      player.playerId,
    )) {
      return _moveToNextPlayer();
    }

    _state = _state.copyWith(
      turnState: TurnState.initial(
        player.playerId,
      ),
    );

    return _state;
  }

  // ============================================================
  // DICE
  // ============================================================

  /// رمي النرد العادي.
  List<MoveOption> rollDice() {
    if (!_state.isStarted) {
      throw StateError(
        'لا يمكن رمي النرد قبل بدء اللعبة.',
      );
    }

    if (_state.isFinished) {
      return const [];
    }

    final turn = _state.turnState;

    if (turn.phase == TurnPhase.playing) {
      throw StateError(
        'يجب تنفيذ الحركات المتاحة قبل رمي النرد مرة أخرى.',
      );
    }

    if (turn.phase == TurnPhase.cancelled ||
        turn.phase == TurnPhase.completed) {
      return const [];
    }

    final sequence = turn.rolls.length + 1;

    final value = _random.nextInt(6) + 1;

    registerDiceRoll(
      value: value,
      sequence: sequence,
    );

    return getValidMoves();
  }

  // ============================================================
  // REGISTER DICE
  // ============================================================

  /// تسجيل رمية محددة.
  ///
  /// مهم:
  /// عدد الـ6 يتم حسابه من جميع رميات الـTurn الحالي،
  /// وليس من الرميات المتتالية.
  ///
  /// مثال:
  ///
  /// 6 -> 4 -> 6
  ///
  /// sixCount = 2
  ///
  /// 6 -> 4 -> 6 -> 3 -> 6
  ///
  /// sixCount = 3 => Cancel Turn
  Object registerDiceRoll({
    required int value,
    required int sequence,
  }) {
    if (!_state.isStarted) {
      throw StateError(
        'لا يمكن تسجيل رمية قبل بدء اللعبة.',
      );
    }

    if (value < 1 || value > 6) {
      throw ArgumentError(
        'قيمة النرد يجب أن تكون من 1 إلى 6.',
      );
    }

    final turn = _state.turnState;

    if (sequence != turn.rolls.length + 1) {
      throw ArgumentError(
        'تسلسل الرميات غير صحيح.',
      );
    }

    final roll = DiceRoll(
      value: value,
      sequence: sequence,
    );

    final updatedRolls = [
      ...turn.rolls,
      roll,
    ];

    // ==========================================================
    // COUNT SIXES IN WHOLE TURN
    // ==========================================================

    final sixCount = updatedRolls
        .where((item) => item.value == 6)
        .length;

    // ==========================================================
    // THIRD SIX IN SAME TURN
    // ==========================================================

    if (value == 6 && sixCount >= 3) {
      _state = _state.copyWith(
        turnState: turn.copyWith(
          rolls: updatedRolls,
          sixRollCount: sixCount,
          availableRolls: const AvailableRolls(),
          phase: TurnPhase.cancelled,
        ),
      );

      return _cancelTurnAndMoveNext();
    }

    // ==========================================================
    // SIX
    // ==========================================================

    if (value == 6) {
      final nextTurn = turn.copyWith(
        rolls: updatedRolls,
        sixRollCount: sixCount,
        availableRolls: _addAvailableRoll(
          turn,
          roll,
        ),
        phase: TurnPhase.rolling,
      );

      _state = _state.copyWith(
        turnState: nextTurn,
      );

      return const <MoveOption>[];
    }

    // ==========================================================
    // NON-SIX
    // ==========================================================

    final nextTurn = turn.copyWith(
      rolls: updatedRolls,
      sixRollCount: sixCount,
      availableRolls: _addAvailableRoll(
        turn,
        roll,
      ),
      phase: TurnPhase.playing,
    );

    _state = _state.copyWith(
      turnState: nextTurn,
    );

    final moves = getValidMoves();

    if (moves.isEmpty) {
      return _finishTurnWithoutMove();
    }

    return moves;
  }

  // ============================================================
  // VALID MOVES
  // ============================================================

  List<MoveOption> getValidMoves() {
    final turn = _state.turnState;

    if (turn.phase != TurnPhase.playing) {
      return const [];
    }

    if (turn.availableRolls.isEmpty) {
      return const [];
    }

    final player = _state.currentPlayer;

    final moves = <MoveOption>[];

    for (final roll in turn.availableRolls.rolls) {
      for (final token in player.tokens) {
        final option = _getMoveOptionForToken(
          player: player,
          token: token,
          roll: roll,
        );

        if (option != null) {
          moves.add(option);
        }
      }
    }

    return List.unmodifiable(moves);
  }

  // ============================================================
  // EXECUTE MOVE
  // ============================================================

  LudoGameState executeMove(
      MoveOption move,
      ) {
    if (!_state.isStarted) {
      throw StateError(
        'اللعبة لم تبدأ.',
      );
    }

    if (_state.isFinished) {
      throw StateError(
        'اللعبة انتهت بالفعل.',
      );
    }

    final validMoves = getValidMoves();

    final isValid = validMoves.any(
          (option) => _sameMove(
        option,
        move,
      ),
    );

    if (!isValid) {
      throw StateError(
        'الحركة المحددة غير قانونية.',
      );
    }

    // ==========================================================
    // EXECUTE
    // ==========================================================

    if (move is ExitToken) {
      _executeExitToken(move);
    } else if (move is MoveToken) {
      _executeMoveToken(move);
    } else {
      throw StateError(
        'نوع الحركة غير مدعوم.',
      );
    }

    // ==========================================================
    // GET UPDATED CURRENT PLAYER
    // ==========================================================

    final updatedPlayer = _state.currentPlayer;

    // ==========================================================
    // FINISH PLAYER
    // ==========================================================

    final hasFinished =
    _hasPlayerFinished(updatedPlayer);

    if (hasFinished &&
        !_state.finishedPlayerIds.contains(
          updatedPlayer.playerId,
        )) {
      _registerPlayerFinished(
        updatedPlayer.playerId,
      );
    }

    // ==========================================================
    // CONSUME USED ROLL
    // ==========================================================

    final updatedTurn = _consumeRoll(
      move.rollSequence,
    );

    _state = _state.copyWith(
      turnState: updatedTurn,
    );

    // ==========================================================
    // GAME FINISHED
    // ==========================================================

    if (_state.finishedPlayerIds.length ==
        _state.players.length) {
      _state = _state.copyWith(
        isFinished: true,
        turnState: updatedTurn.copyWith(
          phase: TurnPhase.completed,
        ),
      );

      return _state;
    }

    // ==========================================================
    // CAPTURE EXTRA ROLL
    // ==========================================================

    //
    // لو الحركة نتج عنها Capture:
    //
    // Capture
    //    ↓
    // Immediate Extra Roll
    //
    // لا نضيف Roll وهمي إلى availableRolls.
    // فقط نرجع phase إلى rolling.
    //
    if (_lastMoveWasCapture) {
      _state = _state.copyWith(
        turnState: updatedTurn.copyWith(
          phase: TurnPhase.rolling,
        ),
      );

      _lastMoveWasCapture = false;

      return _state;
    }

    // ==========================================================
    // REMAINING ROLLS
    // ==========================================================

    if (_state.turnState.availableRolls.isNotEmpty) {
      final remainingMoves =
      getValidMoves();

      if (remainingMoves.isEmpty) {
        return _finishTurnWithoutMove();
      }

      return _state;
    }

    // ==========================================================
    // NEXT PLAYER
    // ==========================================================

    return _moveToNextPlayer();
  }

  // ============================================================
  // LAST MOVE RESULT
  // ============================================================

  bool _lastMoveWasCapture = false;

  // ============================================================
  // MOVE CALCULATION
  // ============================================================

  MoveOption? _getMoveOptionForToken({
    required LudoPlayer player,
    required LudoToken token,
    required DiceRoll roll,
  }) {
    // Finished token.
    if (token.state == LudoTokenState.finished) {
      return null;
    }

    // ==========================================================
    // EXIT TOKEN
    // ==========================================================

    if (token.state == LudoTokenState.initial) {
      if (roll.value != 6) {
        return null;
      }

      return ExitToken(
        tokenId: token.id,
        rollSequence: roll.sequence,
      );
    }

    // ==========================================================
    // MOVABLE TOKEN
    // ==========================================================

    if (token.state != LudoTokenState.normal &&
        token.state != LudoTokenState.safe &&
        token.state != LudoTokenState.safeInPair) {
      return null;
    }

    final path =
    _pathFor(player.color);

    final destinationStep =
    _calculateDestinationStep(
      path: path,
      currentStep: token.positionInPath,
      steps: roll.value,
      hasCaptured: player.hasCaptured,
    );

    // Cannot go beyond Finish.
    if (destinationStep >
        LudoPath.finishStep) {
      return null;
    }

    final destination =
    path.positionAt(
      step: destinationStep,
      hasCaptured: player.hasCaptured,
    );

    // ==========================================================
    // BLOCK
    // ==========================================================

    if (_isBlockedDestination(
      player: player,
      destination: destination,
    )) {
      return null;
    }

    return MoveToken(
      tokenId: token.id,
      steps: roll.value,
      rollSequence: roll.sequence,
    );
  }

  // ============================================================
  // DESTINATION CALCULATION
  // ============================================================

  int _calculateDestinationStep({
    required LudoPath path,
    required int currentStep,
    required int steps,
    required bool hasCaptured,
  }) {
    var step = currentStep;

    for (var i = 0; i < steps; i++) {
      step = path.nextStep(
        currentStep: step,
        hasCaptured: hasCaptured,
      );
    }

    return step;
  }

  // ============================================================
  // BLOCK
  // ============================================================

  bool _isBlockedDestination({
    required LudoPlayer player,
    required Position destination,
  }) {
    // Safe cell never blocks landing.
    if (SafeCells.contains(destination)) {
      return false;
    }

    var ownCount = 0;
    var enemyCount = 0;

    for (final otherPlayer in _state.players) {
      for (final token in otherPlayer.tokens) {
        if (token.state ==
            LudoTokenState.initial ||
            token.state ==
                LudoTokenState.finished) {
          continue;
        }

        if (token.position != destination) {
          continue;
        }

        if (otherPlayer.playerId ==
            player.playerId) {
          ownCount++;
        } else {
          enemyCount++;
        }
      }
    }

    // 2 or more tokens from the same player = Block.
    if (ownCount >= 2) {
      return true;
    }

    // Enemy block cannot be landed on.
    if (enemyCount >= 2) {
      return true;
    }

    return false;
  }

  // ============================================================
  // EXIT TOKEN
  // ============================================================

  void _executeExitToken(
      ExitToken move,
      ) {
    final playerIndex =
        _state.currentPlayerIndex;

    final player =
    _state.players[playerIndex];

    final tokenIndex =
    player.tokens.indexWhere(
          (token) => token.id == move.tokenId,
    );

    if (tokenIndex == -1) {
      throw StateError(
        'الـ Token غير موجود.',
      );
    }

    final token =
    player.tokens[tokenIndex];

    final path =
    _pathFor(player.color);

    final updatedToken =
    token.copyWith(
      position: path.startingPosition,
      positionInPath: 0,
      state: SafeCells.contains(
        path.startingPosition,
      )
          ? LudoTokenState.safe
          : LudoTokenState.normal,
    );

    final updatedTokens =
    [...player.tokens];

    updatedTokens[tokenIndex] =
        updatedToken;

    final updatedPlayer =
    player.copyWith(
      tokens: updatedTokens,
    );

    final updatedPlayers =
    [..._state.players];

    updatedPlayers[playerIndex] =
        updatedPlayer;

    _state = _state.copyWith(
      players: updatedPlayers,
    );
  }

  // ============================================================
  // NORMAL MOVEMENT
  // ============================================================

  void _executeMoveToken(
      MoveToken move,
      ) {
    final playerIndex =
        _state.currentPlayerIndex;

    final player =
    _state.players[playerIndex];

    final tokenIndex =
    player.tokens.indexWhere(
          (token) => token.id == move.tokenId,
    );

    if (tokenIndex == -1) {
      throw StateError(
        'الـ Token غير موجود.',
      );
    }

    final token =
    player.tokens[tokenIndex];

    final path =
    _pathFor(player.color);

    final newPathIndex =
    _calculateDestinationStep(
      path: path,
      currentStep: token.positionInPath,
      steps: move.steps,
      hasCaptured: player.hasCaptured,
    );

    if (newPathIndex >
        LudoPath.finishStep) {
      throw StateError(
        'الحركة تتجاوز نهاية المسار.',
      );
    }

    final newPosition =
    path.positionAt(
      step: newPathIndex,
      hasCaptured: player.hasCaptured,
    );

    // ==========================================================
    // CAPTURE
    // ==========================================================

    final captureOccurred =
    _applyCaptureIfNeeded(
      attackerPlayerId: player.playerId,
      destination: newPosition,
    );

    _lastMoveWasCapture =
        captureOccurred;

    // ==========================================================
    // TOKEN STATE
    // ==========================================================

    final reachesFinish =
        newPathIndex ==
            LudoPath.finishStep;

    final updatedState =
    reachesFinish
        ? LudoTokenState.finished
        : SafeCells.contains(newPosition)
        ? LudoTokenState.safe
        : LudoTokenState.normal;

    final updatedToken =
    token.copyWith(
      position: newPosition,
      positionInPath: newPathIndex,
      state: updatedState,
    );

    final updatedTokens =
    [...player.tokens];

    updatedTokens[tokenIndex] =
        updatedToken;

    // ==========================================================
    // hasCaptured
    // ==========================================================

    final updatedPlayer =
    player.copyWith(
      tokens: updatedTokens,
      hasCaptured:
      player.hasCaptured ||
          captureOccurred,
    );

    final updatedPlayers =
    [..._state.players];

    updatedPlayers[playerIndex] =
        updatedPlayer;

    _state = _state.copyWith(
      players: updatedPlayers,
    );
  }

  // ============================================================
  // CAPTURE
  // ============================================================

  bool _applyCaptureIfNeeded({
    required String attackerPlayerId,
    required Position destination,
  }) {
    // Safe cells are immune.
    if (SafeCells.contains(destination)) {
      return false;
    }

    var captured = false;

    final updatedPlayers =
    <LudoPlayer>[];

    for (final player in _state.players) {
      if (player.playerId ==
          attackerPlayerId) {
        updatedPlayers.add(player);
        continue;
      }

      final playerPath =
      _pathFor(player.color);

      final updatedTokens =
      <LudoToken>[];

      for (final token in player.tokens) {
        final canBeCaptured =
            token.state !=
                LudoTokenState.initial &&
                token.state !=
                    LudoTokenState.finished;

        if (canBeCaptured &&
            token.position ==
                destination) {
          updatedTokens.add(
            token.copyWith(
              position:
              playerPath.startingPosition,
              positionInPath: 0,
              state:
              LudoTokenState.normal,
            ),
          );

          captured = true;
        } else {
          updatedTokens.add(token);
        }
      }

      updatedPlayers.add(
        player.copyWith(
          tokens: updatedTokens,
        ),
      );
    }

    if (captured) {
      _state = _state.copyWith(
        players: updatedPlayers,
      );
    }

    return captured;
  }

  // ============================================================
  // FINISH PLAYER
  // ============================================================

  bool _hasPlayerFinished(
      LudoPlayer player,
      ) {
    return player.tokens.any(
          (token) =>
      token.state ==
          LudoTokenState.finished,
    );
  }

  void _registerPlayerFinished(
      String playerId,
      ) {
    if (_state.finishedPlayerIds.contains(
      playerId,
    )) {
      return;
    }

    _state = _state.copyWith(
      finishedPlayerIds: [
        ..._state.finishedPlayerIds,
        playerId,
      ],
    );
  }

  // ============================================================
  // TURN MANAGEMENT
  // ============================================================

  LudoGameState _finishTurnWithoutMove() {
    return _moveToNextPlayer();
  }

  LudoGameState _cancelTurnAndMoveNext() {
    _lastMoveWasCapture = false;

    return _moveToNextPlayer();
  }

  LudoGameState _moveToNextPlayer() {
    if (_state.isFinished) {
      return _state;
    }

    final totalPlayers =
        _state.players.length;

    if (totalPlayers == 0) {
      return _state;
    }

    for (var offset = 1;
    offset <= totalPlayers;
    offset++) {
      final nextIndex =
          (_state.currentPlayerIndex +
              offset) %
              totalPlayers;

      final nextPlayer =
      _state.players[nextIndex];

      if (!_state.finishedPlayerIds.contains(
        nextPlayer.playerId,
      )) {
        _state = _state.copyWith(
          currentPlayerIndex:
          nextIndex,
          turnState:
          TurnState.initial(
            nextPlayer.playerId,
          ),
        );

        return _state;
      }
    }

    _state = _state.copyWith(
      isFinished: true,
      turnState:
      _state.turnState.copyWith(
        phase: TurnPhase.completed,
      ),
    );

    return _state;
  }

  // ============================================================
  // ROLL MANAGEMENT
  // ============================================================

  AvailableRolls _addAvailableRoll(
      TurnState turn,
      DiceRoll roll,
      ) {
    return turn.availableRolls.add(
      roll,
    );
  }

  TurnState _consumeRoll(
      int rollSequence,
      ) {
    return _state.turnState.copyWith(
      availableRolls:
      _state.turnState.availableRolls
          .removeBySequence(
        rollSequence,
      ),
    );
  }

  // ============================================================
  // PATH
  // ============================================================

  LudoPath _pathFor(
      LudoPlayerColor color,
      ) {
    return LudoPaths.forColor(color);
  }

  // ============================================================
  // MOVE COMPARISON
  // ============================================================

  bool _sameMove(
      MoveOption a,
      MoveOption b,
      ) {
    if (a.runtimeType !=
        b.runtimeType) {
      return false;
    }

    if (a is MoveToken &&
        b is MoveToken) {
      return a.tokenId == b.tokenId &&
          a.steps == b.steps &&
          a.rollSequence ==
              b.rollSequence;
    }

    if (a is ExitToken &&
        b is ExitToken) {
      return a.tokenId == b.tokenId &&
          a.rollSequence ==
              b.rollSequence;
    }

    return false;
  }

  // ============================================================
  // FAST MODE
  // ============================================================

  LudoPlayer _prepareFastModePlayer(
      LudoPlayer player,
      ) {
    if (player.tokens.isEmpty) {
      return player;
    }

    final path = _pathFor(player.color);

    final updatedTokens = [
      ...player.tokens,
    ];

    final firstTokenIndex =
    updatedTokens.indexWhere(
          (token) => token.tokenIndex == 0,
    );

    if (firstTokenIndex == -1) {
      return player;
    }

    final firstToken =
    updatedTokens[firstTokenIndex];

    if (firstToken.state ==
        LudoTokenState.initial) {
      final startPosition =
          path.startingPosition;

      updatedTokens[firstTokenIndex] =
          firstToken.copyWith(
            position: startPosition,
            positionInPath: 0,
            state: SafeCells.contains(
              startPosition,
            )
                ? LudoTokenState.safe
                : LudoTokenState.normal,
          );
    }

    return player.copyWith(
      tokens: updatedTokens,
    );
  }
}
