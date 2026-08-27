import 'dart:math';

import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';

import '../constants/ludo_paths.dart';
import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/position.dart';
import '../models/dice_roll.dart';
import '../models/game_result.dart';
import '../models/ludo_game_state.dart';
import '../models/move_option.dart';
import '../models/turn_state.dart';

class LudoGameEngine {
  LudoGameState _state;

  final Random _random;

  LudoGameEngine({
    required LudoGameState initialState,
    Random? random,
  })  : _state = initialState,
        _random = random ?? Random();

  // ============================================================
  // STATE
  // ============================================================

  LudoGameState get state => _state;

  LudoPlayer get currentPlayer =>
      _state.currentPlayer;

  bool get isStarted =>
      _state.isStarted;

  bool get isFinished =>
      _state.isFinished;

  // ============================================================
  // GAME START
  // ============================================================

  /// بدء المباراة في Fast Mode.
  ///
  /// كل لاعب يبدأ بـ Token واحد خارج البيت
  /// على Starting Cell الخاصة به.
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

    return _state;
  }

  // ============================================================
  // TURN
  // ============================================================

  LudoGameState startTurn() {
    if (!_state.isStarted ||
        _state.isFinished) {
      return _state;
    }

    final player =
        _state.currentPlayer;

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

  /// رمية فعلية باستخدام Random.
  ///
  /// في الاختبارات يفضل استخدام:
  /// registerDiceRoll()
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

    final sequence =
        turn.rolls.length + 1;

    final value =
        _random.nextInt(6) + 1;

    registerDiceRoll(
      value: value,
      sequence: sequence,
    );

    if (_state.turnState.phase !=
        TurnPhase.playing) {
      return const [];
    }

    return _handleAvailableMovesAfterRoll();
  }

  /// تسجيل رمية محددة.
  ///
  /// هذه الدالة مناسبة جدًا للـ Unit Tests.
  ///
  /// مثال:
  ///
  /// registerDiceRoll(value: 6, sequence: 1)
  /// registerDiceRoll(value: 6, sequence: 2)
  /// registerDiceRoll(value: 4, sequence: 3)
  LudoGameState registerDiceRoll({
    required int value,
    required int sequence,
  }) {
    if (value < 1 || value > 6) {
      throw ArgumentError(
        'قيمة النرد يجب أن تكون من 1 إلى 6.',
      );
    }

    final turn = _state.turnState;

    if (sequence !=
        turn.rolls.length + 1) {
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
    // SIX
    // ==========================================================

    if (roll.isSix) {
      final updatedSixCount =
          turn.sixRollCount + 1;

      // ثالث 6 داخل نفس الـ Turn.
      //
      // لا يشترط أن تكون الثلاث 6 متتالية.
      //
      // مثال:
      // 6 → 4 → 6 → 3 → 6
      //
      // = 3 sixRollCount
      if (updatedSixCount >= 3) {
        _state = _state.copyWith(
          turnState: turn.copyWith(
            rolls: updatedRolls,
            availableRolls:
            const AvailableRolls(),
            sixRollCount:
            updatedSixCount,
            phase: TurnPhase.cancelled,
          ),
        );

        return _cancelTurnAndMoveNext();
      }

      final nextTurn = turn.copyWith(
        rolls: updatedRolls,
        availableRolls:
        _addAvailableRoll(
          turn,
          roll,
        ),
        sixRollCount:
        updatedSixCount,
        phase: TurnPhase.rolling,
      );

      _state = _state.copyWith(
        turnState: nextTurn,
      );

      return _state;
    }

    // ==========================================================
    // NON-SIX
    // ==========================================================

    final nextTurn = turn.copyWith(
      rolls: updatedRolls,
      availableRolls:
      _addAvailableRoll(
        turn,
        roll,
      ),

      // مهم:
      // لا نصفر sixRollCount.
      //
      // لأن القاعدة عندنا تحسب عدد الـ 6
      // داخل الـ Turn كله، وليس المتتالية فقط.
      sixRollCount:
      turn.sixRollCount,

      phase: TurnPhase.playing,
    );

    _state = _state.copyWith(
      turnState: nextTurn,
    );

    return _state;
  }

  // ============================================================
  // VALID MOVES
  // ============================================================

  List<MoveOption> getValidMoves() {
    final turn = _state.turnState;

    if (turn.phase !=
        TurnPhase.playing) {
      return const [];
    }

    if (turn.availableRolls.isEmpty) {
      return const [];
    }

    final player =
        _state.currentPlayer;

    final moves =
    <MoveOption>[];

    for (final roll
    in turn.availableRolls.rolls) {
      for (final token
      in player.tokens) {
        final option =
        _getMoveOptionForToken(
          player: player,
          token: token,
          roll: roll,
        );

        if (option != null) {
          moves.add(option);
        }
      }
    }

    return List.unmodifiable(
      moves,
    );
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

    final validMoves =
    getValidMoves();

    final isValid =
    validMoves.any(
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

    if (move is ExitToken) {
      _executeExitToken(move);
    } else if (move is MoveToken) {
      _executeMoveToken(move);
    } else {
      throw StateError(
        'نوع الحركة غير مدعوم.',
      );
    }

    final updatedPlayer =
        _state.currentPlayer;

    // ==========================================================
    // FAST MODE FINISH
    // ==========================================================

    final hasFinished =
    _hasPlayerFinished(
      updatedPlayer,
    );

    if (hasFinished &&
        !_state.finishedPlayerIds
            .contains(
          updatedPlayer.playerId,
        )) {
      _registerPlayerFinished(
        updatedPlayer.playerId,
      );
    }

    // ==========================================================
    // CONSUME ROLL
    // ==========================================================

    final updatedTurn =
    _consumeRoll(
      move.rollSequence,
    );

    _state = _state.copyWith(
      turnState: updatedTurn,
    );

    // ==========================================================
    // GAME FINISHED
    // ==========================================================

    if (_state.finishedPlayerIds
        .length ==
        _state.players.length) {
      _state = _state.copyWith(
        isFinished: true,
        turnState:
        updatedTurn.copyWith(
          phase:
          TurnPhase.completed,
        ),
      );

      return _state;
    }

    // ==========================================================
    // MORE ROLLS
    // ==========================================================

    if (_state.turnState
        .availableRolls.isNotEmpty) {
      final remainingMoves =
      getValidMoves();

      if (remainingMoves
          .isEmpty) {
        return _finishTurnWithoutMove();
      }

      return _state;
    }

    // ==========================================================
    // TURN END
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
    if (token.state ==
        LudoTokenState.finished) {
      return null;
    }

    // ==========================================================
    // EXIT TOKEN
    // ==========================================================

    if (token.state ==
        LudoTokenState.initial) {
      if (roll.value != 6) {
        return null;
      }

      return ExitToken(
        tokenId: token.id,
        rollSequence:
        roll.sequence,
      );
    }

    // ==========================================================
    // NORMAL MOVEMENT
    // ==========================================================

    if (token.state ==
        LudoTokenState.normal ||
        token.state ==
            LudoTokenState.safe ||
        token.state ==
            LudoTokenState.safeInPair) {
      final path =
      _pathFor(player.color);

      final destinationIndex =
          token.positionInPath +
              roll.value;

      if (destinationIndex >=
          path.length) {
        return null;
      }

      return MoveToken(
        tokenId: token.id,
        steps: roll.value,
        rollSequence:
        roll.sequence,
      );
    }

    return null;
  }

  // ============================================================
  // EXECUTE EXIT
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
          (token) =>
      token.id == move.tokenId,
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

    if (path.isEmpty) {
      throw StateError(
        'مسار اللاعب غير موجود.',
      );
    }

    final updatedToken =
    token.copyWith(
      position: path.first,
      positionInPath: 0,
      state:
      LudoTokenState.normal,
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
  // EXECUTE NORMAL MOVEMENT
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
          (token) =>
      token.id == move.tokenId,
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
        token.positionInPath +
            move.steps;

    if (newPathIndex >=
        path.length) {
      throw StateError(
        'الحركة تتجاوز نهاية المسار.',
      );
    }

    final reachesFinish =
        newPathIndex ==
            path.length - 1;

    final updatedToken =
    token.copyWith(
      position:
      path[newPathIndex],
      positionInPath:
      newPathIndex,
      state: reachesFinish
          ? LudoTokenState.finished
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

    // Capture سيتم إضافته بعد تثبيت:
    // Safe Cells
    // Blocks
    // Capture Rules
    //
    // وعند Capture:
    // لا نزود sixRollCount هنا.
    //
    // إنما نمنح رمية فورية جديدة،
    // والـ registerDiceRoll() هو الذي
    // سيزيد sixRollCount لو الرمية الجديدة = 6.
  }

  // ============================================================
  // FINISH PLAYER
  // ============================================================

  /// Fast Mode:
  /// أول Token يصل للنهاية = Player Finished.
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
    if (_state.finishedPlayerIds
        .contains(playerId)) {
      return;
    }

    final updatedFinished = [
      ..._state.finishedPlayerIds,
      playerId,
    ];

    _state = _state.copyWith(
      finishedPlayerIds:
      updatedFinished,
    );
  }

  // ============================================================
  // TURN MANAGEMENT
  // ============================================================

  LudoGameState _finishTurnWithoutMove() {
    return _moveToNextPlayer();
  }

  LudoGameState _cancelTurnAndMoveNext() {
    return _moveToNextPlayer();
  }

  LudoGameState _moveToNextPlayer() {
    if (_state.isFinished) {
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

      if (!_state.finishedPlayerIds
          .contains(
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
        phase:
        TurnPhase.completed,
      ),
    );

    return _state;
  }

  // ============================================================
  // ROLL HELPERS
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

  List<MoveOption>
  _handleAvailableMovesAfterRoll() {
    if (_state.turnState.phase !=
        TurnPhase.playing) {
      return const [];
    }

    final moves =
    getValidMoves();

    if (moves.isEmpty) {
      _finishTurnWithoutMove();
      return const [];
    }

    return moves;
  }

  // ============================================================
  // PATH
  // ============================================================

  List<Position> _pathFor(
      LudoPlayerColor color,
      ) {
    switch (color) {
      case LudoPlayerColor.green:
        return LudoPaths.green;

      case LudoPlayerColor.yellow:
        return LudoPaths.yellow;

      case LudoPlayerColor.blue:
        return LudoPaths.blue;

      case LudoPlayerColor.red:
        return LudoPaths.red;
    }
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
      return a.tokenId ==
          b.tokenId &&
          a.steps == b.steps &&
          a.rollSequence ==
              b.rollSequence;
    }

    if (a is ExitToken &&
        b is ExitToken) {
      return a.tokenId ==
          b.tokenId &&
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

    final path =
    _pathFor(player.color);

    if (path.isEmpty) {
      return player;
    }

    final updatedTokens =
    [...player.tokens];

    final firstTokenIndex =
    updatedTokens.indexWhere(
          (token) =>
      token.tokenIndex == 0,
    );

    if (firstTokenIndex == -1) {
      return player;
    }

    final firstToken =
    updatedTokens[firstTokenIndex];

    if (firstToken.state ==
        LudoTokenState.initial) {
      updatedTokens[firstTokenIndex] =
          firstToken.copyWith(
            position: path.first,
            positionInPath: 0,
            state:
            LudoTokenState.normal,
          );
    }

    return player.copyWith(
      tokens: updatedTokens,
    );
  }

  // ============================================================
  // GAME RESULT
  // ============================================================

  GameResult getResult() {
    final results =
    <GamePlayerResult>[];

    for (var index = 0;
    index <
        _state.finishedPlayerIds
            .length;
    index++) {
      final playerId =
      _state.finishedPlayerIds[
      index];

      results.add(
        GamePlayerResult(
          playerId: playerId,
          rank: index + 1,
          finished: true,
        ),
      );
    }

    return GameResult(
      players: results,
      isFinished:
      _state.isFinished,
    );
  }
}