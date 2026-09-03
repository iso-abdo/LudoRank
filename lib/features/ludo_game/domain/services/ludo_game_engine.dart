import 'dart:math';

import '../constants/ludo_paths.dart';
import '../constants/safe_cells.dart';
import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/position.dart';
import '../models/available_rolls.dart';
import '../models/dice_roll.dart';
import '../models/game_result.dart';
import '../models/ludo_game_state.dart';
import '../models/move_option.dart';
import '../models/turn_state.dart';

/// Core domain engine for a Fast Mode Ludo match.
///
/// Responsibilities:
/// - Game start
/// - Turn management
/// - Dice rolls
/// - Available rolls
/// - Move validation
/// - Token movement
/// - Safe cells
/// - Blocks
/// - Capture
/// - Capture unlocks Home Lane
/// - Capture grants an immediate extra roll
/// - Exact finish
/// - Player ranking
/// - Game completion
///
/// Explicitly NOT responsible for:
/// - Tournament points
/// - Withdrawal
/// - Leaderboard
/// - Persistence
/// - SQLite / Drift
/// - Provider
/// - UI
class LudoGameEngine {
  LudoGameState _state;

  final Random _random;

  /// Used to carry the result of the most recently executed move
  /// into the turn-transition logic.
  bool _lastMoveWasCapture = false;

  LudoGameEngine({
    required LudoGameState initialState,
    Random? random,
  })  : _state = initialState,
        _random = random ?? Random();

  // ============================================================
  // GETTERS
  // ============================================================

  /// Current complete game state.
  LudoGameState get state => _state;

  /// Current player according to the turn order.
  LudoPlayer get currentPlayer => _state.currentPlayer;

  bool get isStarted => _state.isStarted;

  bool get isFinished => _state.isFinished;

  // ============================================================
  // GAME START
  // ============================================================

  /// Starts the Fast Mode match.
  ///
  /// Fast Mode rule:
  /// Every player starts with exactly one token outside Home,
  /// on the player's own starting cell.
  ///
  /// All other tokens remain initial.
  LudoGameState startGame() {
    if (_state.isStarted) {
      return _state;
    }

    if (_state.players.isEmpty) {
      throw StateError(
        'لا يمكن بدء اللعبة بدون لاعبين.',
      );
    }

    final players = _state.players
        .map(_prepareFastModePlayer)
        .toList(growable: false);

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

    _lastMoveWasCapture = false;

    return _state;
  }

  // ============================================================
  // TURN
  // ============================================================

  /// Resets the current player's turn.
  ///
  /// Normally the engine already creates the next turn
  /// automatically, but keeping this operation public is useful
  /// for the controller layer.
  LudoGameState startTurn() {
    if (!_state.isStarted || _state.isFinished) {
      return _state;
    }

    if (_state.currentPlayerFinished) {
      return _moveToNextPlayer();
    }

    final player = _state.currentPlayer;

    _lastMoveWasCapture = false;

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

  /// Rolls a real/random die for the current turn.
  ///
  /// Rules:
  ///
  /// 1..5
  ///   - The roll becomes available.
  ///   - The turn enters Playing.
  ///
  /// 6
  ///   - The roll becomes available.
  ///   - The turn remains Rolling.
  ///   - The player must roll again.
  ///
  /// Third 6 in the SAME turn:
  ///   - The complete turn is cancelled.
  ///   - All previously available rolls are discarded.
  ///   - The turn moves to the next player.
  List<MoveOption> rollDice() {
    _ensureGameStarted();

    if (_state.isFinished) {
      return const [];
    }

    final turn = _state.turnState;

    if (turn.phase == TurnPhase.playing) {
      throw StateError(
        'يجب تنفيذ حركة متاحة قبل رمي النرد مرة أخرى.',
      );
    }

    if (turn.phase == TurnPhase.cancelled ||
        turn.phase == TurnPhase.completed) {
      return const [];
    }

    final sequence = turn.rolls.length + 1;
    final value = _random.nextInt(6) + 1;

    return registerDiceRoll(
      value: value,
      sequence: sequence,
    );
  }

  // ============================================================
  // REGISTER DICE
  // ============================================================

  /// Registers a deterministic dice result.
  ///
  /// This method is intentionally public because the unit tests
  /// need to inject exact dice values.
  List<MoveOption> registerDiceRoll({
    required int value,
    required int sequence,
  }) {
    _ensureGameStarted();

    if (_state.isFinished) {
      return const [];
    }

    if (value < 1 || value > 6) {
      throw ArgumentError(
        'قيمة النرد يجب أن تكون من 1 إلى 6.',
      );
    }

    final turn = _state.turnState;

    if (turn.phase != TurnPhase.rolling) {
      throw StateError(
        'لا يمكن تسجيل رمية جديدة خارج مرحلة Rolling.',
      );
    }

    final expectedSequence = turn.rolls.length + 1;

    if (sequence != expectedSequence) {
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
    // COUNT ALL SIXES IN THIS TURN
    // ==========================================================
    // IMPORTANT:
    // Count ALL sixes in the current turn.
    //
    // Example:
    // 6 -> 4 -> 6 -> 3 -> 6
    //
    // = 3 sixes
    final sixRollCount = updatedRolls
        .where((item) => item.isSix)
        .length;

    // ==========================================================
    // THIRD SIX IN SAME TURN
    // ==========================================================

    if (sixRollCount >= 3) {
      _state = _state.copyWith(
        turnState: turn.copyWith(
          rolls: updatedRolls,
          availableRolls: const AvailableRolls(),
          sixRollCount: sixRollCount,
          phase: TurnPhase.cancelled,
        ),
      );

      _cancelTurnAndMoveNext();

      return const [];
    }

    // ==========================================================
    // SIX
    // ==========================================================

    if (roll.isSix) {
      final nextTurn = turn.copyWith(
        rolls: updatedRolls,
        availableRolls: turn.availableRolls.add(
          roll,
        ),
        sixRollCount: sixRollCount,
        phase: TurnPhase.rolling,
      );

      _state = _state.copyWith(
        turnState: nextTurn,
      );

      return const [];
    }

    // ==========================================================
    // NON-SIX
    // ==========================================================

    final nextTurn = turn.copyWith(
      rolls: updatedRolls,
      availableRolls: turn.availableRolls.add(
        roll,
      ),
      sixRollCount: sixRollCount,
      phase: TurnPhase.playing,
    );

    _state = _state.copyWith(
      turnState: nextTurn,
    );

    final moves = getValidMoves();

    // No legal move with ANY currently available roll.
    if (moves.isEmpty) {
      _finishTurnWithoutMove();
      return const [];
    }

    return moves;
  }

  // ============================================================
  // VALID MOVES
  // ============================================================

  /// Returns every legal move available to the current player.
  ///
  /// The player may choose:
  /// - any legal token
  /// - with any currently available roll
  ///
  /// The Engine never auto-selects a move.
  List<MoveOption> getValidMoves() {
    final turn = _state.turnState;

    if (!_state.isStarted || _state.isFinished) {
      return const [];
    }

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
        final move = _getMoveOptionForToken(
          player: player,
          token: token,
          roll: roll,
        );

        if (move != null) {
          moves.add(move);
        }
      }
    }

    return List.unmodifiable(moves);
  }

  // ============================================================
  // EXECUTE MOVE
  // ============================================================

  /// Executes a move selected by the player.
  ///
  /// The move MUST exist in [getValidMoves].
  LudoGameState executeMove(
      MoveOption move,
      ) {
    _ensureGameStarted();

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

    _lastMoveWasCapture = false;

    // ==========================================================
    // EXECUTE ACTUAL MOVE
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
    // UPDATED PLAYER
    // ==========================================================

    final updatedPlayer = _state.currentPlayer;

    // ==========================================================
    // RANK PLAYER IF FINISHED
    // ==========================================================

    final playerFinished =
    _hasPlayerFinished(updatedPlayer);

    if (playerFinished) {
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
    // ALL PLAYERS FINISHED
    // ==========================================================

    if (_allPlayersFinished) {
      _state = _state.copyWith(
        isFinished: true,
        turnState: updatedTurn.copyWith(
          phase: TurnPhase.completed,
        ),
      );

      _lastMoveWasCapture = false;

      return _state;
    }

    // ==========================================================
    // PLAYER FINISHED -> LEAVE TURN IMMEDIATELY
    // ==========================================================

    //
    // IMPORTANT:
    // In Fast Mode the first token finishing is enough to rank
    // the player. That player must not continue consuming the
    // remaining rolls of the same turn.
    //
    if (playerFinished) {
      _lastMoveWasCapture = false;

      return _moveToNextPlayer();
    }

    // ==========================================================
    // CAPTURE -> IMMEDIATE EXTRA ROLL
    // ==========================================================

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
    // REMAINING AVAILABLE ROLLS
    // ==========================================================

    if (_state.turnState.availableRolls.isNotEmpty) {
      final remainingMoves = getValidMoves();

      if (remainingMoves.isEmpty) {
        return _finishTurnWithoutMove();
      }

      return _state;
    }

    // ==========================================================
    // NO ROLLS LEFT
    // ==========================================================

    return _moveToNextPlayer();
  }

  // ============================================================
  // MOVE CALCULATION
  // ============================================================

  MoveOption? _getMoveOptionForToken({
    required LudoPlayer player,
    required LudoToken token,
    required DiceRoll roll,
  }) {
    // Finished token cannot move.
    if (token.isFinished) {
      return null;
    }

    // ==========================================================
    // EXIT TOKEN
    // ==========================================================

    if (token.isInitial) {
      if (!roll.isSix) {
        return null;
      }

      //
      // Starting Cells are safe cells in our board definition,
      // therefore an exit is always legal with respect to blocks.
      //
      return ExitToken(
        tokenId: token.id,
        rollSequence: roll.sequence,
      );
    }

    // ==========================================================
    // MOVABLE TOKEN
    // ==========================================================

    final isMovableState =
        token.state == LudoTokenState.normal ||
            token.state == LudoTokenState.safe ||
            token.state == LudoTokenState.safeInPair;

    if (!isMovableState) {
      return null;
    }

    if (token.positionInPath < 0 ||
        token.positionInPath > LudoPath.finishStep) {
      return null;
    }

    final path = _pathFor(
      player.color,
    );

    // Resolve destination by walking the actual logical path.
    //
    // This is critical because step 51 has two meanings:
    //
    // Before Capture:
    //   50 -> 51 -> 0
    //
    // After Capture:
    //   50 -> 51(Home) -> 52 ...
    final destinationStep =
    _calculateDestinationStep(
      path: path,
      currentStep: token.positionInPath,
      steps: roll.value,
      hasCaptured: player.hasCaptured,
    );

    // Exact finish:
    // reaching 56 is legal,
    // going beyond 56 is not.
    if (destinationStep > LudoPath.finishStep) {
      return null;
    }

    final destination = path.positionAt(
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

  /// Walks the logical path one step at a time.
  ///
  /// This MUST be used instead of:
  ///
  ///   currentStep + steps
  ///
  /// because the meaning of step 51 changes after Capture.
  int _calculateDestinationStep({
    required LudoPath path,
    required int currentStep,
    required int steps,
    required bool hasCaptured,
  }) {
    if (steps < 0) {
      throw ArgumentError(
        'عدد الخطوات لا يمكن أن يكون سالبًا.',
      );
    }

    var step = currentStep;

    for (var i = 0; i < steps; i++) {
      step = path.nextStep(
        currentStep: step,
        hasCaptured: hasCaptured,
      );

      //
      // Once Finish is reached, it is terminal.
      //
      if (step == LudoPath.finishStep &&
          i < steps - 1) {
        //
        // Keep advancing to Finish so the final returned value
        // remains 56. The caller will reject the move only if
        // it exceeds the exact finish requirement.
        //
        continue;
      }
    }

    return step;
  }

  // ============================================================
  // BLOCKS
  // ============================================================

  /// Determines whether a destination is blocked.
  ///
  /// Rules:
  ///
  /// - Safe cells never block landing.
  /// - 2+ own tokens on an ordinary cell = own block.
  /// - 2+ enemy tokens on an ordinary cell = enemy block.
  /// - Exactly 1 enemy token may be landed on and captured.
  ///
  /// Movement may pass over blocks; only the final destination
  /// is checked here.
  bool _isBlockedDestination({
    required LudoPlayer player,
    required Position destination,
  }) {
    if (SafeCells.contains(destination)) {
      return false;
    }

    var ownCount = 0;
    var enemyCount = 0;

    for (final otherPlayer in _state.players) {
      for (final token in otherPlayer.tokens) {
        if (token.isInitial || token.isFinished) {
          continue;
        }

        if (token.position != destination) {
          continue;
        }

        if (otherPlayer.playerId == player.playerId) {
          ownCount++;
        } else {
          enemyCount++;
        }
      }
    }

    // Own block.
    if (ownCount >= 2) {
      return true;
    }

    // Enemy block.
    if (enemyCount >= 2) {
      return true;
    }

    return false;
  }

  // ============================================================
  // EXIT TOKEN
  // ============================================================

  /// Moves an initial token onto its own starting cell.
  void _executeExitToken(
      ExitToken move,
      ) {
    final playerIndex =
        _state.currentPlayerIndex;

    final player =
    _state.players[playerIndex];

    final tokenIndex = player.tokens.indexWhere(
          (token) => token.id == move.tokenId,
    );

    if (tokenIndex == -1) {
      throw StateError(
        'الـ Token غير موجود.',
      );
    }

    final token =
    player.tokens[tokenIndex];

    if (!token.isInitial) {
      throw StateError(
        'الـ Token ليس في الحالة Initial.',
      );
    }

    final path =
    _pathFor(player.color);

    final startingPosition =
        path.startingPosition;

    final updatedToken =
    token.copyWith(
      position: startingPosition,
      positionInPath: 0,
      state: SafeCells.contains(
        startingPosition,
      )
          ? LudoTokenState.safe
          : LudoTokenState.normal,
    );

    final updatedTokens = [
      ...player.tokens,
    ];

    updatedTokens[tokenIndex] =
        updatedToken;

    final updatedPlayer =
    player.copyWith(
      tokens: updatedTokens,
    );

    final updatedPlayers = [
      ..._state.players,
    ];

    updatedPlayers[playerIndex] =
        updatedPlayer;

    _state = _state.copyWith(
      players: updatedPlayers,
    );
  }

  // ============================================================
  // NORMAL TOKEN MOVEMENT
  // ============================================================

  /// Executes a token movement along the actual logical path.
  void _executeMoveToken(
      MoveToken move,
      ) {
    final playerIndex =
        _state.currentPlayerIndex;

    final player =
    _state.players[playerIndex];

    final tokenIndex = player.tokens.indexWhere(
          (token) => token.id == move.tokenId,
    );

    if (tokenIndex == -1) {
      throw StateError(
        'الـ Token غير موجود.',
      );
    }

    final token =
    player.tokens[tokenIndex];

    if (token.isInitial || token.isFinished) {
      throw StateError(
        'الـ Token غير قابل للحركة.',
      );
    }

    final path =
    _pathFor(player.color);

    final newPathIndex =
    _calculateDestinationStep(
      path: path,
      currentStep: token.positionInPath,
      steps: move.steps,
      hasCaptured: player.hasCaptured,
    );

    if (newPathIndex > LudoPath.finishStep) {
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

    final nextTokenState =
    reachesFinish
        ? LudoTokenState.finished
        : SafeCells.contains(
      newPosition,
    )
        ? LudoTokenState.safe
        : LudoTokenState.normal;

    final updatedToken =
    token.copyWith(
      position: newPosition,
      positionInPath: newPathIndex,
      state: nextTokenState,
    );

    final updatedTokens = [
      ...player.tokens,
    ];

    updatedTokens[tokenIndex] =
        updatedToken;

    // ==========================================================
    // PLAYER hasCaptured
    // ==========================================================

    final updatedPlayer =
    player.copyWith(
      tokens: updatedTokens,
      hasCaptured:
      player.hasCaptured ||
          captureOccurred,
    );

    final updatedPlayers = [
      ..._state.players,
    ];

    updatedPlayers[playerIndex] =
        updatedPlayer;

    _state = _state.copyWith(
      players: updatedPlayers,
    );
  }

  // ============================================================
  // CAPTURE
  // ============================================================

  /// Captures exactly one enemy token on an ordinary cell.
  ///
  /// Rules:
  /// - Safe cells are immune.
  /// - Exactly one enemy token can be captured.
  /// - Enemy block (2+) is already rejected by
  ///   [_isBlockedDestination].
  ///
  /// Captured token returns to its own starting cell.
  bool _applyCaptureIfNeeded({
    required String attackerPlayerId,
    required Position destination,
  }) {
    // Safe cells cannot be captured on.
    if (SafeCells.contains(destination)) {
      return false;
    }

    for (var playerIndex = 0;
    playerIndex < _state.players.length;
    playerIndex++) {
      final player =
      _state.players[playerIndex];

      // Do not capture own tokens.
      if (player.playerId == attackerPlayerId) {
        continue;
      }

      final tokenIndex =
      player.tokens.indexWhere(
            (token) =>
        !token.isInitial &&
            !token.isFinished &&
            token.position == destination,
      );

      if (tokenIndex == -1) {
        continue;
      }

      final path =
      _pathFor(player.color);

      final defenderToken =
      player.tokens[tokenIndex];

      final resetToken =
      defenderToken.copyWith(
        position: path.startingPosition,
        positionInPath: 0,
        state: SafeCells.contains(
          path.startingPosition,
        )
            ? LudoTokenState.safe
            : LudoTokenState.normal,
      );

      final updatedTokens = [
        ...player.tokens,
      ];

      updatedTokens[tokenIndex] =
          resetToken;

      final updatedPlayer =
      player.copyWith(
        tokens: updatedTokens,
      );

      final updatedPlayers = [
        ..._state.players,
      ];

      updatedPlayers[playerIndex] =
          updatedPlayer;

      _state = _state.copyWith(
        players: updatedPlayers,
      );

      return true;
    }

    return false;
  }

  // ============================================================
  // PLAYER FINISH / RANKING
  // ============================================================

  /// In Fast Mode:
  /// one finished token is enough to rank the player.
  bool _hasPlayerFinished(
      LudoPlayer player,
      ) {
    return player.tokens.any(
          (token) => token.isFinished,
    );
  }

  /// Registers a player's rank.
  ///
  /// The order in finishedPlayerIds is the rank:
  ///
  /// index 0 -> rank 1
  /// index 1 -> rank 2
  /// ...
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

  bool get _allPlayersFinished {
    return _state.finishedPlayerIds.length ==
        _state.players.length;
  }

  // ============================================================
  // TURN TRANSITIONS
  // ============================================================

  LudoGameState _finishTurnWithoutMove() {
    return _moveToNextPlayer();
  }

  LudoGameState _cancelTurnAndMoveNext() {
    _lastMoveWasCapture = false;

    return _moveToNextPlayer();
  }

  /// Moves to the next unfinished player.
  ///
  /// Finished players are skipped permanently.
  LudoGameState _moveToNextPlayer() {
    if (_state.isFinished) {
      return _state;
    }

    if (_state.players.isEmpty) {
      throw StateError(
        'اللعبة لا تحتوي على لاعبين.',
      );
    }

    if (_allPlayersFinished) {
      _state = _state.copyWith(
        isFinished: true,
        turnState:
        _state.turnState.copyWith(
          phase: TurnPhase.completed,
        ),
      );

      return _state;
    }

    final totalPlayers =
        _state.players.length;

    for (var offset = 1;
    offset <= totalPlayers;
    offset++) {
      final nextIndex =
          (_state.currentPlayerIndex +
              offset) %
              totalPlayers;

      final nextPlayer =
      _state.players[nextIndex];

      final isFinished =
      _state.finishedPlayerIds.contains(
        nextPlayer.playerId,
      );

      if (isFinished) {
        continue;
      }

      _state = _state.copyWith(
        currentPlayerIndex: nextIndex,
        turnState:
        TurnState.initial(
          nextPlayer.playerId,
        ),
      );

      _lastMoveWasCapture = false;

      return _state;
    }

    // No unfinished player exists.
    _state = _state.copyWith(
      isFinished: true,
      turnState:
      _state.turnState.copyWith(
        phase: TurnPhase.completed,
      ),
    );

    _lastMoveWasCapture = false;

    return _state;
  }

  // ============================================================
  // ROLL MANAGEMENT
  // ============================================================

  TurnState _consumeRoll(
      int rollSequence,
      ) {
    if (!_state.turnState.availableRolls
        .containsSequence(rollSequence)) {
      throw StateError(
        'الرمية المطلوبة غير متاحة للاستهلاك.',
      );
    }

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
  // FAST MODE PREPARATION
  // ============================================================

  /// Prepares one player for Fast Mode.
  ///
  /// Token index 0 starts on the player's Starting Cell.
  /// All other tokens remain untouched.
  LudoPlayer _prepareFastModePlayer(
      LudoPlayer player,
      ) {
    if (player.tokens.isEmpty) {
      throw StateError(
        'اللاعب ${player.playerId} لا يملك أي Token.',
      );
    }

    final path =
    _pathFor(player.color);

    final firstTokenIndex =
    player.tokens.indexWhere(
          (token) => token.tokenIndex == 0,
    );

    if (firstTokenIndex == -1) {
      throw StateError(
        'اللاعب ${player.playerId} لا يملك Token رقم 0.',
      );
    }

    final updatedTokens = [
      ...player.tokens,
    ];

    final firstToken =
    updatedTokens[firstTokenIndex];

    //
    // Only initialize Token #0 when it is still in Home.
    //
    if (firstToken.isInitial) {
      final startingPosition =
          path.startingPosition;

      updatedTokens[firstTokenIndex] =
          firstToken.copyWith(
            position: startingPosition,
            positionInPath: 0,
            state: SafeCells.contains(
              startingPosition,
            )
                ? LudoTokenState.safe
                : LudoTokenState.normal,
          );
    }

    return player.copyWith(
      tokens: updatedTokens,
    );
  }

  // ============================================================
  // GAME RESULT
  // ============================================================

  /// Builds the domain-level result.
  ///
  /// Tournament points are NOT calculated here.
  GameResult getResult() {
    final results =
    <GamePlayerResult>[];

    for (var index = 0;
    index < _state.finishedPlayerIds.length;
    index++) {
      results.add(
        GamePlayerResult(
          playerId:
          _state.finishedPlayerIds[index],
          rank: index + 1,
          finished: true,
        ),
      );
    }

    return GameResult(
      players: List.unmodifiable(
        results,
      ),
      isFinished: _state.isFinished,
    );
  }

  // ============================================================
  // VALIDATION HELPERS
  // ============================================================

  void _ensureGameStarted() {
    if (!_state.isStarted) {
      throw StateError(
        'اللعبة لم تبدأ.',
      );
    }
  }
}