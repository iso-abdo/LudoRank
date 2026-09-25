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

class MatchGameProvider extends ChangeNotifier {
  final MatchGameService service;

  MatchGameSession? _session;

  MatchStatus? _matchStatus;

  final List<MatchPlayer> _completedPlayers = [];

  String? _selectedTokenId;

  bool _isLoading = false;

  String? _error;

  MatchGameProvider({
    required this.service,
  });

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
    return _session?.state.players ??
        const <LudoPlayer>[];
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
    return _session
        ?.engine
        .state
        .turnState
        .availableRolls ??
        const AvailableRolls();
  }

  List<MoveOption> get availableMoves {
    return _session?.engine.getValidMoves() ??
        const <MoveOption>[];
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

    if (currentSession == null ||
        !currentSession.isFinished) {
      return null;
    }

    return currentSession.result;
  }

  List<MatchPlayer> get completedPlayers {
    return List.unmodifiable(
      _completedPlayers,
    );
  }

  // ============================================================
  // UI STATE
  // ============================================================

  MatchStatus? get matchStatus => _matchStatus;

  String? get selectedTokenId => _selectedTokenId;

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

    _completedPlayers.clear();

    try {
      final createdSession =
      await service.startMatch(
        matchId: matchId,
        playerNames: playerNames,
        random: random,
      );

      _session = createdSession;

      _matchStatus =
          createdSession.match.status;
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

    if (currentSession == null) {
      _setError(
        'لا توجد جلسة مباراة نشطة.',
      );
      return;
    }

    try {
      _error = null;

      _selectedTokenId = null;

      currentSession.engine.rollDice();

      notifyListeners();
    } catch (e) {
      _error = e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // SELECT TOKEN
  // ============================================================

  /// UI-only token selection.
  ///
  /// This method NEVER moves a token
  /// and NEVER changes the LudoGameEngine.
  void selectToken(String tokenId) {
    if (_selectedTokenId == tokenId) {
      _selectedTokenId = null;
    } else {
      _selectedTokenId = tokenId;
    }

    notifyListeners();
  }

  void clearSelection() {
    if (_selectedTokenId == null) {
      return;
    }

    _selectedTokenId = null;

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
  Future<void> executeMove(
      MoveOption move,
      ) async {
    final currentSession = _session;

    if (currentSession == null) {
      _setError(
        'لا توجد جلسة مباراة نشطة.',
      );
      return;
    }

    try {
      _error = null;

      currentSession.engine.executeMove(
        move,
      );

      _selectedTokenId = null;

      // Immediately update the game UI.
      notifyListeners();

      // ========================================================
      // GAME FINISHED
      // ========================================================

      if (currentSession.isFinished &&
          _matchStatus != MatchStatus.finished) {
        await _completeFinishedMatch();
      }
    } catch (e) {
      _error = e.toString();

      notifyListeners();
    }
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
      _setError(
        'لا توجد جلسة مباراة نشطة.',
      );
      return;
    }

    if (!currentSession.isFinished) {
      _setError(
        'محرك اللعبة لم ينتهِ بعد.',
      );
      return;
    }

    if (_matchStatus == MatchStatus.finished) {
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final updatedPlayers =
      await service.completeMatch(
        currentSession,
      );

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
      _setError(
        'لا توجد جلسة مباراة نشطة.',
      );
      return;
    }

    if (!currentSession.isFinished) {
      _setError(
        'لا يمكن إعادة حفظ النتيجة قبل انتهاء اللعبة.',
      );
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

    _error = null;

    _isLoading = false;

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