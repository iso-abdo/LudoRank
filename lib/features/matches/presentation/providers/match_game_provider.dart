import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_status.dart';
import '../../domain/services/match_game_service.dart';
import '../../domain/services/match_game_session.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';

class MatchGameProvider extends ChangeNotifier {
  final MatchGameService service;

  MatchGameSession? _session;

  MatchStatus? _matchStatus;

  final List<MatchPlayer> _completedPlayers = [];

  String? _selectedTokenId;
  int? _selectedRollSequence;

  // الحركة الوحيدة المنتظرة للتنفيذ التلقائي.
  MoveOption? _pendingAutoMove;

  // حماية من استدعاء التنفيذ التلقائي أكثر من مرة.
  bool _isAutoMoveExecuting = false;
  bool _isLoading = false;

  String? _error;

  MatchGameProvider({required this.service});
  // ============================================================
  // CONSTRUCTOR AND DESTRUCTOR isAutoMove
  // ======================================
  MoveOption? get pendingAutoMove => _pendingAutoMove;

  bool get isAutoMoveExecuting => _isAutoMoveExecuting;

  // ============================================================
  // SESSION
  // ============================================================

  MatchGameSession? get session => _session;

  /// Match metadata snapshot.
  ///
  /// IMPORTANT:
  /// status هنا هو الـ snapshot الأصلي الموجود داخل Session.
  /// استخدم [matchStatus] لمعرفة الـ lifecycle الحالي.
  Match? get match => _session?.match;

  // ============================================================
  // GAME STATE
  // ============================================================

  LudoGameState? get state => _session?.state;

  List<LudoPlayer> get players {
    return _session?.state.players ?? const <LudoPlayer>[];
  }

  LudoPlayer? get currentPlayer {
    return _session?.engine.currentPlayer;
  }

  String? get currentPlayerId {
    return _session?.currentPlayerId;
  }

  // ============================================================
  // TURN
  // ============================================================

  TurnState? get turnState {
    return _session?.engine.state.turnState;
  }

  AvailableRolls get availableRolls {
    return _session?.engine.state.turnState.availableRolls ??
        const AvailableRolls();
  }

  List<MoveOption> get availableMoves {
    return _session?.engine.getValidMoves() ?? const <MoveOption>[];
  }

  // ===========================
  /// Legal destinations for the currently selected token.
  /// Each destination keeps the original MoveOption objects.
  /// =============================
  Map<Position, List<MoveOption>> get selectedMoveDestinations {
    final session = _session;
    final tokenId = _selectedTokenId;

    if (session == null || tokenId == null) {
      return const <Position, List<MoveOption>>{};
    }

    final result = <Position, List<MoveOption>>{};

    for (final move in availableMoves) {
      final moveTokenId = switch (move) {
        MoveToken(:final tokenId) => tokenId,
        ExitToken(:final tokenId) => tokenId,
      };

      if (moveTokenId != tokenId) continue;

      final destination = session.engine.getMoveDestination(move);
      if (destination == null) continue;

      result.putIfAbsent(destination, () => <MoveOption>[]).add(move);
    }

    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<MoveOption>.unmodifiable(entry.value),
    });
  }

  /// Gets the visible dice value for a legal move without exposing its sequence.
  int? rollValueForMove(MoveOption move) {
    return availableRolls.getBySequence(move.rollSequence)?.value;
  }

  /// Executes the exact legal option selected on the board.
  Future<void> handleBoardMoveTap(MoveOption move) async {
    if (!availableMoves.any((candidate) {
      if (candidate is MoveToken && move is MoveToken) {
        return candidate.tokenId == move.tokenId &&
            candidate.steps == move.steps &&
            candidate.rollSequence == move.rollSequence;
      }

      if (candidate is ExitToken && move is ExitToken) {
        return candidate.tokenId == move.tokenId &&
            candidate.rollSequence == move.rollSequence;
      }

      return false;
    })) {
      return;
    }

    await executeMove(move);
  }

  // ============================================================
  // RESULT
  // ============================================================

  /// Final GameResult.
  ///
  /// قبل انتهاء اللعبة:
  /// null
  ///
  /// بعد انتهاء الـ Engine:
  /// يحتوي على ترتيب اللاعبين.
  GameResult? get result {
    final currentSession = _session;

    if (currentSession == null || !currentSession.isFinished) {
      return null;
    }

    return currentSession.result;
  }

  List<MatchPlayer> get completedPlayers {
    return List.unmodifiable(_completedPlayers);
  }

  // ============================================================
  // UI STATE
  // ============================================================

  MatchStatus? get matchStatus => _matchStatus;

  String? get selectedTokenId => _selectedTokenId;
  int? get selectedRollSequence => _selectedRollSequence;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool get isStarted {
    return _session?.isStarted ?? false;
  }

  /// هل محرك Ludo انتهى بالفعل؟
  ///
  /// قد تكون true بينما ما زلنا نحفظ النتيجة في DB.
  bool get isGameFinished {
    return _session?.isFinished ?? false;
  }

  /// هل Match نفسها أصبحت Finished في persistence؟
  bool get isFinished {
    return _matchStatus == MatchStatus.finished;
  }

  bool get isPlaying {
    return _matchStatus == MatchStatus.playing;
  }

  bool get canRollDice {
    return isStarted &&
        !isLoading &&
        !isGameFinished &&
        turnState?.isRolling == true;
  }

  bool get canExecuteMove {
    return isStarted &&
        !isLoading &&
        !isGameFinished &&
        turnState?.isPlaying == true &&
        availableMoves.isNotEmpty;
  }

  // ============================================================
  // ROLL DICE HELPERS
  // ============================================================
  AvailableRolls get selectableRolls {
    final legalSequences = availableMoves
        .where((move) {
          if (_selectedTokenId == null) return true;

          if (move is MoveToken) {
            return move.tokenId == _selectedTokenId;
          }

          if (move is ExitToken) {
            return move.tokenId == _selectedTokenId;
          }

          return false;
        })
        .map((move) => move.rollSequence)
        .toSet();

    return AvailableRolls(
      rolls: availableRolls.rolls
          .where((roll) => legalSequences.contains(roll.sequence))
          .toList(growable: false),
    );
  }

  // ============================================================
  // START MATCH
  // ============================================================

  /// Starts a brand-new Pending Match.
  ///
  /// Pending -> Playing
  ///
  /// This method does NOT resume an existing Playing Match.
  Future<void> startMatch({
    required String matchId,
    required Map<String, String> playerNames,
    Random? random,
  }) async {
    _setLoading(true);
    _error = null;

    _selectedTokenId = null;
    _selectedRollSequence = null;

    _completedPlayers.clear();

    try {
      final createdSession = await service.startMatch(
        matchId: matchId,
        playerNames: playerNames,
        random: random,
      );

      _session = createdSession;

      _matchStatus = createdSession.match.status;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ROLL DICE
  // ============================================================

  /// Rolls the dice through LudoGameEngine.
  ///
  /// All dice rules remain inside the Engine:
  /// - normal rolls
  /// - six
  /// - multiple sixes
  /// - third-six cancellation
  /// - no-legal-move handling
  void rollDice() {
    final currentSession = _session;

    if (currentSession == null ||
        isLoading ||
        isGameFinished ||
        turnState?.isRolling != true) {
      return;
    }

    try {
      _error = null;

      _selectedTokenId = null;
      _selectedRollSequence = null;
      _pendingAutoMove = null;
      _isAutoMoveExecuting = false;
      //

      // المحرك وحده مسؤول عن قواعد رمي النرد.
      currentSession.engine.rollDice();

      // اكتشاف الحركة الوحيدة من قائمة الحركات القانونية.
      final legalMoves = availableMoves;

      if (turnState?.isPlaying == true && legalMoves.length == 1) {
        _pendingAutoMove = legalMoves.single;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _pendingAutoMove = null;

      notifyListeners();
    }
  }

  // ===========================================================
  //  executePendingAutoMove
  //============================================================
  Future<void> executePendingAutoMove() async {
    if (_isAutoMoveExecuting || isLoading || isGameFinished) {
      return;
    }

    final move = _pendingAutoMove;
    final currentSession = _session;

    if (move == null ||
        currentSession == null ||
        turnState?.isPlaying != true) {
      return;
    }

    // نتحقق أن الحركة ما زالت قانونية قبل تنفيذها.
    final isStillLegal = availableMoves.any((candidate) {
      if (candidate is MoveToken && move is MoveToken) {
        return candidate.tokenId == move.tokenId &&
            candidate.steps == move.steps &&
            candidate.rollSequence == move.rollSequence;
      }

      if (candidate is ExitToken && move is ExitToken) {
        return candidate.tokenId == move.tokenId &&
            candidate.rollSequence == move.rollSequence;
      }

      return false;
    });

    if (!isStillLegal) {
      _pendingAutoMove = null;
      notifyListeners();
      return;
    }

    // قفل التنفيذ قبل أي عملية غير متزامنة.
    _isAutoMoveExecuting = true;
    _pendingAutoMove = null;

    notifyListeners();

    try {
      await executeMove(move);
    } finally {
      _isAutoMoveExecuting = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SELECT TOKEN
  // ============================================================
  /// Handles a token tap using the legal moves from LudoGameEngine.
  ///
  /// One legal move  -> execute immediately.
  /// Multiple moves  -> select the token and show its move options.
  /// No legal moves  -> do not move the token.
  Future<void> handleTokenTap(LudoToken token) async {
    final currentSession = _session;
    final activePlayer = currentPlayer;

    if (currentSession == null ||
        activePlayer == null ||
        token.playerId != activePlayer.playerId ||
        turnState?.isPlaying != true ||
        isLoading ||
        currentSession.isFinished) {
      return;
    }

    final tokenMoves = availableMoves
        .where((move) {
          if (move is MoveToken) return move.tokenId == token.id;
          if (move is ExitToken) return move.tokenId == token.id;
          return false;
        })
        .toList(growable: false);

    if (tokenMoves.isEmpty) return;

    // إذا اختير النرد أولًا، نحاول تنفيذ الحركة المطابقة له فقط.
    if (_selectedRollSequence != null) {
      final matchingMoves = tokenMoves
          .where((move) => move.rollSequence == _selectedRollSequence)
          .toList(growable: false);

      if (matchingMoves.length == 1) {
        await executeMove(matchingMoves.single);
        return;
      }

      if (matchingMoves.isNotEmpty) {
        _selectedTokenId = token.id;
        notifyListeners();
        return;
      }

      // الرمية المختارة لا تناسب هذا التوكن.
      // نحدد التوكن ونترك الواجهة تعرض رمياته القانونية.
      _selectedTokenId = token.id;
      _selectedRollSequence = null;
      notifyListeners();
      return;
    }

    // لمسة واحدة تكفي عندما توجد حركة قانونية واحدة فقط.
    if (tokenMoves.length == 1) {
      await executeMove(tokenMoves.single);
      return;
    }

    // تعدد الحركات: نحدد التوكن ليختار اللاعب النرد المناسب.
    _selectedTokenId = token.id;
    notifyListeners();
  }

  //
  /// UI-only token selection
  ///
  /// This method NEVER moves a token
  /// and NEVER changes the LudoGameEngine.
  void selectToken(String tokenId) {
    if (_selectedTokenId == tokenId) {
      _selectedTokenId = null;
      _selectedRollSequence = null;
    } else {
      _selectedTokenId = tokenId;
    }

    notifyListeners();
  }

  void clearSelection() {
    if (_selectedTokenId == null && _selectedRollSequence == null) {
      return;
    }

    _selectedTokenId = null;
    _selectedRollSequence = null;

    notifyListeners();
  }

  // ============================================================
  // EXECUTE MOVE
  // ============================================================

  /// Executes an already validated MoveOption through
  /// the LudoGameEngine.
  ///
  /// If the move finishes the complete Ludo game,
  /// the provider automatically persists the Match.
  Future<void> executeMove(MoveOption move) async {
    final currentSession = _session;

    if (_isAutoMoveExecuting &&
        _pendingAutoMove != null &&
        move != _pendingAutoMove) {
      return;
    }

    if (currentSession == null) {
      _setError('لا توجد جلسة مباراة نشطة.');
      return;
    }

    try {
      _error = null;

      currentSession.engine.executeMove(move);

      _selectedTokenId = null;
      _selectedRollSequence = null;
      _pendingAutoMove = null;
      _selectedTokenId = null;
      _selectedRollSequence = null;

      // Immediately update the game UI.
      notifyListeners();

      // ========================================================
      // GAME FINISHED
      // ========================================================

      if (currentSession.isFinished && _matchStatus != MatchStatus.finished) {
        await _completeFinishedMatch();
      }
    } catch (e) {
      _error = e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // HANDLE ROLL TAP
  // ============================================================
  Future<void> handleAvailableRollTap(int sequence) async {
    if (turnState?.isPlaying != true ||
        isLoading ||
        isGameFinished ||
        !availableRolls.containsSequence(sequence)) {
      return;
    }

    final options = availableMoves
        .where((move) {
          if (move.rollSequence != sequence) return false;

          if (_selectedTokenId == null) return true;

          if (move is MoveToken) {
            return move.tokenId == _selectedTokenId;
          }

          if (move is ExitToken) {
            return move.tokenId == _selectedTokenId;
          }

          return false;
        })
        .toList(growable: false);

    if (options.isEmpty) return;

    // عند تحديد توكن، اختيار النرد ينفذ الحركة القانونية المرتبطة به.
    if (_selectedTokenId != null && options.length == 1) {
      await executeMove(options.single);
      return;
    }

    // قبل تحديد التوكن، نحتفظ باختيار النرد حتى يختار اللاعب حجرًا.
    _selectedRollSequence = sequence;
    notifyListeners();
  }

  // ============================================================
  // COMPLETE FINISHED MATCH
  // ============================================================

  /// Internal lifecycle operation.
  ///
  /// The UI does NOT call this directly.
  Future<void> _completeFinishedMatch() async {
    final currentSession = _session;

    if (currentSession == null) {
      _setError('لا توجد جلسة مباراة نشطة.');
      return;
    }

    if (!currentSession.isFinished) {
      _setError('محرك اللعبة لم ينتهِ بعد.');
      return;
    }

    if (_matchStatus == MatchStatus.finished) {
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final updatedPlayers = await service.completeMatch(currentSession);

      _completedPlayers
        ..clear()
        ..addAll(updatedPlayers);

      _matchStatus = MatchStatus.finished;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // RETRY FINAL PERSISTENCE
  // ============================================================

  /// Used only when the Ludo engine already finished
  /// but persistence failed.
  ///
  /// This is NOT the normal match-completion flow.
  Future<void> retryFinishPersistence() async {
    final currentSession = _session;

    if (currentSession == null) {
      _setError('لا توجد جلسة مباراة نشطة.');
      return;
    }

    if (!currentSession.isFinished) {
      _setError('لا يمكن إعادة حفظ النتيجة قبل انتهاء اللعبة.');
      return;
    }

    if (_matchStatus == MatchStatus.finished) {
      return;
    }

    await _completeFinishedMatch();
  }

  // ============================================================
  // RESET
  // ============================================================

  /// Clears runtime/UI state.
  ///
  /// Does NOT delete the Match from the database.
  void reset() {
    _session = null;

    _matchStatus = null;

    _completedPlayers.clear();

    _selectedTokenId = null;

    _selectedRollSequence = null;

    _error = null;

    _isLoading = false;
    _pendingAutoMove = null;
    _isAutoMoveExecuting = false;

    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;

    notifyListeners();
  }

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }

  void _setError(String message) {
    _error = message;

    notifyListeners();
  }
}
