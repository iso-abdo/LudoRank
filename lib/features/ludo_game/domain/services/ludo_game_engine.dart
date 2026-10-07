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

/// نتيجة حساب Destination داخل المسار.
///
/// نحتاج الاثنين معًا لأن Step 51 له تفسيرين:
///
/// - Main Loop Step 51
/// - Home Lane Step 51
///
/// لذلك لا يكفي أن نرجع رقم Step فقط.
class _PathDestination {
  final int step;

  /// true  = Step محسوب على مسار Home Lane
  /// false = Step محسوب على Main Loop
  final bool useHomeLane;

  const _PathDestination({required this.step, required this.useHomeLane});
}

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

  /// Indicates whether the most recently executed move
  /// captured an enemy token.
  ///
  /// This flag is consumed immediately by [executeMove]
  /// to grant the capture bonus roll.
  bool _lastMoveWasCapture = false;

  LudoGameEngine({required LudoGameState initialState, Random? random})
    : _state = initialState,
      _random = random ?? Random();

  // ============================================================
  // GETTERS
  // ============================================================

  /// Current complete game state.
  LudoGameState get state => _state;

  /// Current player according to seat order.
  LudoPlayer get currentPlayer => _state.currentPlayer;

  /// Whether the match has started.
  bool get isStarted => _state.isStarted;

  /// Whether the match has finished.
  bool get isFinished => _state.isFinished;

  // ============================================================
  // GAME START
  // ============================================================

  /// Starts a Fast Mode match.
  ///
  /// Fast Mode:
  /// - Token #0 starts outside Home.
  /// - It starts on the player's own Starting Cell.
  /// - Tokens #1..#3 remain inside Home.
  LudoGameState startGame() {
    if (_state.isStarted) {
      return _state;
    }

    if (_state.players.isEmpty) {
      throw StateError('لا يمكن بدء اللعبة بدون لاعبين.');
    }

    final players = _state.players
        .map(_prepareFastModePlayer)
        .toList(growable: false);

    final firstPlayer = players.first;

    _state = _state.copyWith(
      players: players,
      currentPlayerIndex: 0,
      turnState: TurnState.initial(firstPlayer.playerId),
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

  /// Starts or resets the current player's turn.
  LudoGameState startTurn() {
    if (!_state.isStarted || _state.isFinished) {
      return _state;
    }

    if (_state.currentPlayerFinished) {
      return _moveToNextPlayer();
    }

    final player = _state.currentPlayer;

    _lastMoveWasCapture = false;

    _state = _state.copyWith(turnState: TurnState.initial(player.playerId));

    return _state;
  }

  // ============================================================
  // DICE
  // ============================================================

  /// Rolls the random die.
  ///
  /// Rules:
  ///
  /// 1..5:
  /// - Roll becomes available.
  /// - Turn becomes Playing.
  ///
  /// 6:
  /// - Roll becomes available.
  /// - Turn remains Rolling.
  /// - Player gets another roll.
  ///
  /// Third six in the same turn:
  /// - Entire turn is cancelled.
  /// - All available rolls are discarded.
  /// - Next unfinished player gets the turn.
  List<MoveOption> rollDice() {
    _ensureGameStarted();

    if (_state.isFinished) {
      return const [];
    }

    final turn = _state.turnState;

    if (turn.phase == TurnPhase.playing) {
      throw StateError('يجب تنفيذ حركة متاحة قبل رمي النرد مرة أخرى.');
    }

    if (turn.phase == TurnPhase.cancelled ||
        turn.phase == TurnPhase.completed) {
      return const [];
    }

    final sequence = turn.rolls.length + 1;
    final value = _random.nextInt(6) + 1;

    return registerDiceRoll(value: value, sequence: sequence);
  }

  // ============================================================
  // REGISTER DICE
  // ============================================================

  /// Registers a deterministic dice roll.
  ///
  /// Mainly useful for tests and debugging.
  List<MoveOption> registerDiceRoll({
    required int value,
    required int sequence,
  }) {
    _ensureGameStarted();

    if (_state.isFinished) {
      return const [];
    }

    if (value < 1 || value > 6) {
      throw ArgumentError('قيمة النرد يجب أن تكون من 1 إلى 6.');
    }

    final turn = _state.turnState;

    if (turn.phase != TurnPhase.rolling) {
      throw StateError('لا يمكن تسجيل رمية جديدة خارج مرحلة Rolling.');
    }

    final expectedSequence = turn.rolls.length + 1;

    if (sequence != expectedSequence) {
      throw ArgumentError('تسلسل الرميات غير صحيح.');
    }

    final roll = DiceRoll(value: value, sequence: sequence);

    final updatedRolls = [...turn.rolls, roll];

    // ==========================================================
    // COUNT ALL SIXES
    // ==========================================================

    final sixRollCount = updatedRolls.where((item) => item.isSix).length;

    // ==========================================================
    // THIRD SIX
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
      _state = _state.copyWith(
        turnState: turn.copyWith(
          rolls: updatedRolls,
          availableRolls: turn.availableRolls.add(roll),
          sixRollCount: sixRollCount,
          phase: TurnPhase.rolling,
        ),
      );

      return const [];
    }

    // ==========================================================
    // NON-SIX
    // ==========================================================

    _state = _state.copyWith(
      turnState: turn.copyWith(
        rolls: updatedRolls,
        availableRolls: turn.availableRolls.add(roll),
        sixRollCount: sixRollCount,
        phase: TurnPhase.playing,
      ),
    );

    final moves = getValidMoves();

    // No legal movement at all.
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
  /// - with any available roll
  ///
  /// The engine never auto-selects a token.
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
  LudoGameState executeMove(MoveOption move) {
    _ensureGameStarted();

    if (_state.isFinished) {
      throw StateError('اللعبة انتهت بالفعل.');
    }

    final validMoves = getValidMoves();

    final isValid = validMoves.any((option) => _sameMove(option, move));

    if (!isValid) {
      throw StateError('الحركة المحددة غير قانونية.');
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
      throw StateError('نوع الحركة غير مدعوم.');
    }

    // ==========================================================
    // UPDATED PLAYER
    // ==========================================================

    final updatedPlayer = _state.currentPlayer;

    // ==========================================================
    // PLAYER FINISH
    // ==========================================================

    final playerFinished = _hasPlayerFinished(updatedPlayer);

    if (playerFinished) {
      _registerPlayerFinished(updatedPlayer.playerId);
    }

    // ==========================================================
    // CONSUME USED ROLL
    // ==========================================================

    final updatedTurn = _consumeRoll(move.rollSequence);

    _state = _state.copyWith(turnState: updatedTurn);

    // ==========================================================
    // ALL PLAYERS FINISHED
    // ==========================================================

    if (_allPlayersFinished) {
      _state = _state.copyWith(
        isFinished: true,
        turnState: updatedTurn.copyWith(phase: TurnPhase.completed),
      );

      _lastMoveWasCapture = false;

      return _state;
    }

    // ==========================================================
    // PLAYER FINISHED
    // ==========================================================

    if (playerFinished) {
      _lastMoveWasCapture = false;

      return _moveToNextPlayer();
    }

    // ==========================================================
    // CAPTURE BONUS
    // ==========================================================
    //
    // Capture gives an immediate extra roll.
    //
    // IMPORTANT:
    // We do NOT consume or recreate old rolls here.
    // The capture bonus simply changes the phase to Rolling,
    // which allows one new die roll.
    //
    if (_lastMoveWasCapture) {
      _state = _state.copyWith(
        turnState: updatedTurn.copyWith(phase: TurnPhase.rolling),
      );

      _lastMoveWasCapture = false;

      return _state;
    }

    // ==========================================================
    // REMAINING ROLLS
    // ==========================================================
    //
    // IMPORTANT RULE:
    //
    // وجود 6 متبقية داخل availableRolls لا يعني
    // أن اللاعب يأخذ Roll جديدة تلقائيًا.
    //
    // الـ 6 أعطت الـ Extra Roll لحظة تسجيلها بالفعل.
    //
    // إذا كانت هناك رميات لم تُستخدم بعد:
    // - نظل Playing.
    // - اللاعب يختار إحدى الحركات القانونية.
    //
    if (_state.turnState.availableRolls.isNotEmpty) {
      final remainingMoves = getValidMoves();

      if (remainingMoves.isEmpty) {
        return _finishTurnWithoutMove();
      }

      _state = _state.copyWith(
        turnState: updatedTurn.copyWith(phase: TurnPhase.playing),
      );

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

      return ExitToken(tokenId: token.id, rollSequence: roll.sequence);
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

    final path = _pathFor(player.color);

    // ==========================================================
    // DESTINATION
    // ==========================================================

    final destination = _calculateDestinationStep(
      path: path,
      player: player,
      token: token,
      steps: roll.value,
    );

    if (destination == null) {
      return null;
    }

    final destinationPosition = path.positionAt(
      step: destination.step,
      useHomeLane: destination.useHomeLane,
    );

    // IMPORTANT:
    //
    // Do NOT use only:
    //
    // path.isHomeLaneStep(destination.step)
    //
    // because Step 51 can still be Main Loop.
    //
    final destinationIsHomeLane = destination.useHomeLane;

    if (_isBlockedDestination(
      player: player,
      destination: destinationPosition,
      isHomeLane: destinationIsHomeLane,
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

  _PathDestination? _calculateDestinationStep({
    required LudoPath path,
    required LudoPlayer player,
    required LudoToken token,
    required int steps,
  }) {
    if (steps <= 0) {
      return null;
    }

    if (token.positionInPath < 0 ||
        token.positionInPath > LudoPath.finishStep) {
      return null;
    }

    var step = token.positionInPath;

    // حالة محلية فقط أثناء محاكاة الحركة.
    // لا نعدل الـ Token الحقيقي هنا.
    var homeEntryPending = token.homeEntryPending;

    // هل الـ destination النهائي تم الوصول إليه
    // من خلال Home Lane؟
    var destinationUseHomeLane = false;

    for (var i = 0; i < steps; i++) {
      // Finish نقطة نهائية ولا يمكن تجاوزها.
      if (step == LudoPath.finishStep) {
        return null;
      }

      // ========================================================
      // RESOLVE CURRENT ROUTE
      // ========================================================
      //
      // قبل Capture:
      //   51 = Main Loop
      //
      // بعد Capture:
      //   51 = Home Lane
      //
      // الاستثناء:
      // Token نفسه عند 51 Main Loop ومعه
      // homeEntryPending=true
      //
      // في هذه الحالة:
      //   51(Main) -> 0
      //
      final useHomeLane =
          player.hasCaptured &&
          !(homeEntryPending && step == LudoPath.lastMainLoopStep);

      final nextStep = path.nextStep(
        currentStep: step,
        useHomeLane: useHomeLane,
      );

      // ========================================================
      // RESOLVE DESTINATION SEMANTICS
      // ========================================================
      //
      // الرقم 51 وحده لا يكفي.
      //
      // 50 -> 51 عندما useHomeLane=true
      //      => 51 Home Lane
      //
      // 50 -> 51 عندما useHomeLane=false
      //      => 51 Main Loop
      //
      // 51 -> 0 عندما useHomeLane=false
      //      => 0 Main Loop
      //
      // 51 -> 52 عندما useHomeLane=true
      //      => 52 Home Lane
      //
      destinationUseHomeLane =
          useHomeLane && nextStep >= LudoPath.homeLaneStartStep;

      // ========================================================
      // COMPLETE SPECIAL PENDING STATE
      // ========================================================
      //
      // بمجرد الوصول إلى 51 Home Lane،
      // يكون الـ Token قد أكمل الدورة المطلوبة.
      //
      if (destinationUseHomeLane && nextStep == LudoPath.homeLaneStartStep) {
        homeEntryPending = false;
      }

      step = nextStep;
    }

    return _PathDestination(step: step, useHomeLane: destinationUseHomeLane);
  }

  // ============================================================
  // BLOCKS
  // ============================================================

  /// Determines whether the final destination is blocked.
  ///
  /// Rules:
  /// - Safe cells are never blocked.
  /// - Home Lane is never blocked.
  /// - 2+ own tokens = own block.
  /// - 2+ enemy tokens = enemy block.
  /// - Exactly 1 enemy token is capturable.
  /// - Blocks only affect landing, not passing over.
  bool _isBlockedDestination({
    required LudoPlayer player,
    required Position destination,
    required bool isHomeLane,
  }) {
    if (isHomeLane) {
      return false;
    }

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

  /// Moves an Initial token onto its own Starting Cell.
  void _executeExitToken(ExitToken move) {
    final playerIndex = _state.currentPlayerIndex;

    final player = _state.players[playerIndex];

    final tokenIndex = player.tokens.indexWhere(
      (token) => token.id == move.tokenId,
    );

    if (tokenIndex == -1) {
      throw StateError('الـ Token غير موجود.');
    }

    final token = player.tokens[tokenIndex];

    if (!token.isInitial) {
      throw StateError('الـ Token ليس في الحالة Initial.');
    }

    final path = _pathFor(player.color);

    final startingPosition = path.startingPosition;

    final updatedToken = token.copyWith(
      position: startingPosition,
      positionInPath: 0,
      state: SafeCells.contains(startingPosition)
          ? LudoTokenState.safe
          : LudoTokenState.normal,
      homeEntryPending: false,
    );

    final updatedTokens = [...player.tokens];

    updatedTokens[tokenIndex] = updatedToken;

    final updatedPlayer = player.copyWith(tokens: updatedTokens);

    final updatedPlayers = [..._state.players];

    updatedPlayers[playerIndex] = updatedPlayer;

    _state = _state.copyWith(players: updatedPlayers);
  }

  // ============================================================
  // NORMAL TOKEN MOVEMENT
  // ============================================================

  /// Executes a normal Token movement.
  void _executeMoveToken(MoveToken move) {
    final playerIndex = _state.currentPlayerIndex;

    final player = _state.players[playerIndex];

    final tokenIndex = player.tokens.indexWhere(
      (token) => token.id == move.tokenId,
    );

    if (tokenIndex == -1) {
      throw StateError('الـ Token غير موجود.');
    }

    final token = player.tokens[tokenIndex];

    if (token.isInitial || token.isFinished) {
      throw StateError('الـ Token غير قابل للحركة.');
    }

    final path = _pathFor(player.color);

    // ==========================================================
    // DESTINATION
    // ==========================================================

    final destination = _calculateDestinationStep(
      path: path,
      player: player,
      token: token,
      steps: move.steps,
    );

    if (destination == null) {
      throw StateError('الحركة تتجاوز نهاية المسار.');
    }

    final newPathIndex = destination.step;

    final newPosition = path.positionAt(
      step: destination.step,
      useHomeLane: destination.useHomeLane,
    );

    final reachesFinish = destination.step == LudoPath.finishStep;

    // IMPORTANT:
    //
    // Use the actual route interpretation calculated above.
    //
    // Do not infer Step 51 from its number alone.
    final isHomeLane = destination.useHomeLane;

    // ==========================================================
    // CAPTURE
    // ==========================================================

    var captureOccurred = false;

    if (!reachesFinish && !isHomeLane) {
      captureOccurred = _applyCaptureIfNeeded(
        attackerPlayerId: player.playerId,
        destination: newPosition,
      );
    }

    _lastMoveWasCapture = captureOccurred;

    // ==========================================================
    // HOME ENTRY PENDING
    // ==========================================================
    //
    // Special rule:
    //
    // If THIS token performs the FIRST capture on Main Loop
    // Step 51, it does NOT immediately enter Home Lane.
    //
    // Instead:
    //
    //   51(Main)
    //      ↓
    //   0
    //      ↓
    //   ...
    //      ↓
    //   50
    //      ↓
    //   51(Home)
    //
    final shouldDelayHomeEntry =
        captureOccurred &&
        !player.hasCaptured &&
        newPathIndex == LudoPath.lastMainLoopStep &&
        !isHomeLane;

    final nextHomeEntryPending = reachesFinish
        ? false
        : isHomeLane
        ? false
        : shouldDelayHomeEntry
        ? true
        : token.homeEntryPending;

    // ==========================================================
    // TOKEN STATE
    // ==========================================================

    final nextTokenState = reachesFinish
        ? LudoTokenState.finished
        : isHomeLane
        ? LudoTokenState.safe
        : SafeCells.contains(newPosition)
        ? LudoTokenState.safe
        : LudoTokenState.normal;

    final updatedToken = token.copyWith(
      position: newPosition,
      positionInPath: newPathIndex,
      state: nextTokenState,
      homeEntryPending: nextHomeEntryPending,
    );

    final updatedTokens = [...player.tokens];

    updatedTokens[tokenIndex] = updatedToken;

    // ==========================================================
    // PLAYER CAPTURE STATUS
    // ==========================================================
    //
    // Player-level state:
    //
    // hasCaptured = "this player has unlocked Home Lane"
    //
    // Token-level state:
    //
    // homeEntryPending = "this specific token must complete
    //                     one extra loop before Home Lane"
    //
    final updatedPlayer = player.copyWith(
      tokens: updatedTokens,
      hasCaptured: player.hasCaptured || captureOccurred,
    );

    final updatedPlayers = [..._state.players];

    updatedPlayers[playerIndex] = updatedPlayer;

    _state = _state.copyWith(players: updatedPlayers);
  }

  // ============================================================
  // CAPTURE
  // ============================================================

  /// Captures exactly one enemy token on
  /// an ordinary non-safe Main Loop cell.
  ///
  /// Returns true when a capture happened.
  ///
  /// IMPORTANT:
  /// The defender returns to Home / Initial.
  /// It does NOT return to its Starting Cell.
  bool _applyCaptureIfNeeded({
    required String attackerPlayerId,
    required Position destination,
  }) {
    // Safe cells cannot be captured.
    if (SafeCells.contains(destination)) {
      return false;
    }

    // Home Lane cannot contain captures.
    //
    // We check all Home Lanes because physical positions
    // belonging to Home Lane are never valid capture targets.
    for (final player in _state.players) {
      final path = _pathFor(player.color);

      if (path.homePath.contains(destination)) {
        return false;
      }
    }

    for (
      var playerIndex = 0;
      playerIndex < _state.players.length;
      playerIndex++
    ) {
      final player = _state.players[playerIndex];

      if (player.playerId == attackerPlayerId) {
        continue;
      }

      final tokenIndex = player.tokens.indexWhere(
        (token) =>
            !token.isInitial &&
            !token.isFinished &&
            token.position == destination,
      );

      if (tokenIndex == -1) {
        continue;
      }

      final defenderToken = player.tokens[tokenIndex];

      // ========================================================
      // RESET DEFENDER TO HOME
      // ========================================================
      //
      // This is intentionally:
      //
      // positionInPath = -1
      // state = initial
      // position = (0, 0)
      //
      // It does NOT use defenderPath.startingPosition.
      final resetToken = defenderToken.copyWith(
        position: const Position(row: 0, column: 0),
        positionInPath: -1,
        state: LudoTokenState.initial,
        homeEntryPending: false,
      );

      final updatedTokens = [...player.tokens];

      updatedTokens[tokenIndex] = resetToken;

      final updatedPlayer = player.copyWith(tokens: updatedTokens);

      final updatedPlayers = [..._state.players];

      updatedPlayers[playerIndex] = updatedPlayer;

      _state = _state.copyWith(players: updatedPlayers);

      return true;
    }

    return false;
  }

  // ============================================================
  // PLAYER FINISH / RANKING
  // ============================================================

  /// In Fast Mode:
  /// the first finished token is enough
  /// to rank the player.
  bool _hasPlayerFinished(LudoPlayer player) {
    return player.tokens.any((token) => token.isFinished);
  }

  /// Registers the next player rank.
  ///
  /// finishedPlayerIds order = rank order.
  void _registerPlayerFinished(String playerId) {
    if (_state.finishedPlayerIds.contains(playerId)) {
      return;
    }

    _state = _state.copyWith(
      finishedPlayerIds: [..._state.finishedPlayerIds, playerId],
    );
  }

  bool get _allPlayersFinished {
    return _state.finishedPlayerIds.length == _state.players.length;
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
  LudoGameState _moveToNextPlayer() {
    if (_state.isFinished) {
      return _state;
    }

    if (_state.players.isEmpty) {
      throw StateError('اللعبة لا تحتوي على لاعبين.');
    }

    if (_allPlayersFinished) {
      _state = _state.copyWith(
        isFinished: true,
        turnState: _state.turnState.copyWith(phase: TurnPhase.completed),
      );

      return _state;
    }

    final totalPlayers = _state.players.length;

    for (var offset = 1; offset <= totalPlayers; offset++) {
      final nextIndex = (_state.currentPlayerIndex + offset) % totalPlayers;

      final nextPlayer = _state.players[nextIndex];

      if (_state.finishedPlayerIds.contains(nextPlayer.playerId)) {
        continue;
      }

      _state = _state.copyWith(
        currentPlayerIndex: nextIndex,
        turnState: TurnState.initial(nextPlayer.playerId),
      );

      _lastMoveWasCapture = false;

      return _state;
    }

    // Safety fallback.
    _state = _state.copyWith(
      isFinished: true,
      turnState: _state.turnState.copyWith(phase: TurnPhase.completed),
    );

    _lastMoveWasCapture = false;

    return _state;
  }

  // ============================================================
  // ROLL MANAGEMENT
  // ============================================================

  TurnState _consumeRoll(int rollSequence) {
    if (!_state.turnState.availableRolls.containsSequence(rollSequence)) {
      throw StateError('الرمية المطلوبة غير متاحة للاستهلاك.');
    }

    return _state.turnState.copyWith(
      availableRolls: _state.turnState.availableRolls.removeBySequence(
        rollSequence,
      ),
    );
  }

  // ============================================================
  // PATH
  // ============================================================

  LudoPath _pathFor(LudoPlayerColor color) {
    return LudoPaths.forColor(color);
  }

  // ============================================================
  // MOVE COMPARISON
  // ============================================================

  bool _sameMove(MoveOption a, MoveOption b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }

    if (a is MoveToken && b is MoveToken) {
      return a.tokenId == b.tokenId &&
          a.steps == b.steps &&
          a.rollSequence == b.rollSequence;
    }

    if (a is ExitToken && b is ExitToken) {
      return a.tokenId == b.tokenId && a.rollSequence == b.rollSequence;
    }

    return false;
  }

  // ============================================================
  // FAST MODE PREPARATION
  // ============================================================

  /// Prepares a player for Fast Mode.
  ///
  /// Token #0 starts outside Home.
  /// Tokens #1..#3 remain Initial.
  LudoPlayer _prepareFastModePlayer(LudoPlayer player) {
    if (player.tokens.isEmpty) {
      throw StateError('اللاعب ${player.playerId} لا يملك أي Token.');
    }

    final path = _pathFor(player.color);

    final firstTokenIndex = player.tokens.indexWhere(
      (token) => token.tokenIndex == 0,
    );

    if (firstTokenIndex == -1) {
      throw StateError('اللاعب ${player.playerId} لا يملك Token رقم 0.');
    }

    final updatedTokens = [...player.tokens];

    final firstToken = updatedTokens[firstTokenIndex];

    if (firstToken.isInitial) {
      final startingPosition = path.startingPosition;

      updatedTokens[firstTokenIndex] = firstToken.copyWith(
        position: startingPosition,
        positionInPath: 0,
        state: SafeCells.contains(startingPosition)
            ? LudoTokenState.safe
            : LudoTokenState.normal,
        homeEntryPending: false,
      );
    }

    return player.copyWith(tokens: updatedTokens);
  }

  // ============================================================
  // GAME RESULT
  // ============================================================

  /// Builds the domain-level game result.
  ///
  /// Tournament points are intentionally
  /// calculated outside the engine.
  GameResult getResult() {
    final results = <GamePlayerResult>[];

    for (var index = 0; index < _state.finishedPlayerIds.length; index++) {
      final playerId = _state.finishedPlayerIds[index];

      results.add(
        GamePlayerResult(playerId: playerId, rank: index + 1, finished: true),
      );
    }

    return GameResult(players: results, isFinished: _state.isFinished);
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  void _ensureGameStarted() {
    if (!_state.isStarted) {
      throw StateError('اللعبة لم تبدأ.');
    }
  }
}
