import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

import '../entities/match.dart';

import 'package:ludo_rank/features/ludo_game/domain/services/ludo_game_engine.dart';

/// Validates a saved Ludo state before restoring a running match.
///
/// This validator checks consistency between:
/// - Match
/// - MatchPlayer records
/// - LudoGameState
/// - TurnState and its dice rolls
///
/// It does not modify or repair the supplied state.
class MatchGameStateValidator {
  const MatchGameStateValidator();

  void validate({
    required Match match,
    required List<MatchPlayer> matchPlayers,
    required LudoGameState state,
  }) {
    _validateMatchPlayers(match: match, matchPlayers: matchPlayers);
    _validateGameState(match: match, matchPlayers: matchPlayers, state: state);
  }

  void _validateMatchPlayers({
    required Match match,
    required List<MatchPlayer> matchPlayers,
  }) {
    if (match.playersCount < 2 || match.playersCount > 4) {
      _fail('عدد لاعبي المباراة يجب أن يكون 2 أو 3 أو 4.');
    }

    if (matchPlayers.length != match.playersCount) {
      _fail('عدد MatchPlayers لا يطابق عدد لاعبي Match.');
    }

    final playerIds = <String>{};
    final seats = <int>{};

    for (final player in matchPlayers) {
      if (player.matchId != match.id) {
        _fail('يوجد MatchPlayer تابع لمباراة أخرى.');
      }

      if (player.playerId.trim().isEmpty) {
        _fail('يوجد MatchPlayer بدون playerId صالح.');
      }

      if (!playerIds.add(player.playerId)) {
        _fail('اللاعب ${player.playerId} مكرر داخل المباراة.');
      }

      if (player.seat < 1 || player.seat > match.playersCount) {
        _fail('Seat ${player.seat} غير صالح لهذه المباراة.');
      }

      if (!seats.add(player.seat)) {
        _fail('Seat ${player.seat} مكرر.');
      }
    }
  }

  void _validateGameState({
    required Match match,
    required List<MatchPlayer> matchPlayers,
    required LudoGameState state,
  }) {
    if (!state.isStarted) {
      _fail('Snapshot تشير إلى أن اللعبة لم تبدأ.');
    }

    if (state.isFinished) {
      _fail('لا يمكن استعادة مباراة منتهية كأنها مباراة نشطة.');
    }

    if (state.players.length != match.playersCount) {
      _fail('عدد لاعبي Snapshot لا يطابق عدد لاعبي المباراة.');
    }

    if (state.currentPlayerIndex < 0 ||
        state.currentPlayerIndex >= state.players.length) {
      _fail('currentPlayerIndex خارج حدود قائمة اللاعبين.');
    }

    final expectedPlayers = {
      for (final player in matchPlayers) player.playerId: player,
    };

    final actualPlayerIds = <String>{};
    final actualSeats = <int>{};
    final tokenIds = <String>{};

    for (final player in state.players) {
      if (player.playerId.trim().isEmpty) {
        _fail('يوجد لاعب داخل Snapshot بدون playerId صالح.');
      }

      if (!actualPlayerIds.add(player.playerId)) {
        _fail('اللاعب ${player.playerId} مكرر داخل Snapshot.');
      }

      if (!actualSeats.add(player.seat)) {
        _fail('يوجد أكثر من لاعب بنفس Seat داخل Snapshot.');
      }

      final matchPlayer = expectedPlayers[player.playerId];

      if (matchPlayer == null) {
        _fail('اللاعب ${player.playerId} غير موجود في MatchPlayers.');
      }

      if (player.seat != matchPlayer.seat) {
        _fail('Seat اللاعب ${player.playerId} لا يطابق MatchPlayer.');
      }

      for (final token in player.tokens) {
        if (token.playerId != player.playerId) {
          _fail('يوجد Token تابع للاعب مختلف عن مالكه.');
        }

        if (!tokenIds.add(token.id)) {
          _fail('يوجد Token ID مكرر داخل Snapshot.');
        }
      }
    }

    if (actualPlayerIds.length != expectedPlayers.length ||
        !actualPlayerIds.containsAll(expectedPlayers.keys)) {
      _fail('قائمة لاعبي Snapshot لا تطابق لاعبي المباراة.');
    }

    _validateFinishedPlayers(state);
    _validateCurrentPlayer(state);
    _validateTurnState(state);
  }

  void _validateFinishedPlayers(LudoGameState state) {
    final playerIds = state.players.map((player) => player.playerId).toSet();
    final finishedIds = <String>{};

    for (final playerId in state.finishedPlayerIds) {
      if (!playerIds.contains(playerId)) {
        _fail('finishedPlayerIds يحتوي على لاعب غير موجود.');
      }

      if (!finishedIds.add(playerId)) {
        _fail('finishedPlayerIds يحتوي على لاعب مكرر.');
      }

      final player = state.players.firstWhere(
        (item) => item.playerId == playerId,
      );

      if (!player.tokens.any((token) => token.isFinished)) {
        _fail('اللاعب $playerId مسجل كمنتهٍ دون Token في Finish.');
      }
    }

    for (final player in state.players) {
      final isRegisteredFinished = finishedIds.contains(player.playerId);
      final hasFinishedToken = player.tokens.any((token) => token.isFinished);

      if (hasFinishedToken && !isRegisteredFinished) {
        _fail(
          'اللاعب ${player.playerId} لديه Token في Finish '
          'لكنه غير مسجل في finishedPlayerIds.',
        );
      }
    }

    // Fast Mode ends when playersCount - 1 players have finished.
    // Therefore an active match must have fewer finishers than that.
    if (finishedIds.length >= state.players.length - 1) {
      _fail('عدد اللاعبين المنتهين يعني أن المباراة كان يجب أن تنتهي.');
    }
  }

  void _validateCurrentPlayer(LudoGameState state) {
    final currentPlayer = state.players[state.currentPlayerIndex];

    if (state.turnState.playerId.trim().isEmpty) {
      _fail('TurnState لا يحتوي على playerId صالح.');
    }

    if (state.turnState.playerId != currentPlayer.playerId) {
      _fail('TurnState.playerId لا يطابق اللاعب صاحب الدور الحالي.');
    }

    if (state.finishedPlayerIds.contains(currentPlayer.playerId)) {
      _fail('اللاعب الحالي مسجل بالفعل كلاعب منتهٍ.');
    }
  }

  void _validateTurnState(LudoGameState state) {
    final turn = state.turnState;

    if (turn.phase != TurnPhase.rolling && turn.phase != TurnPhase.playing) {
      _fail('مرحلة الدور لا تصلح لاستعادة مباراة نشطة.');
    }
    if (turn.phase == TurnPhase.playing) {
      final engine = LudoGameEngine(initialState: state);

      if (engine.getValidMoves().isEmpty) {
        _fail('مرحلة playing لا تحتوي على أي حركة قانونية.');
      }
    }

    _validateRollHistory(turn);
    _validateAvailableRolls(turn);

    final actualSixCount = turn.rolls.where((roll) => roll.isSix).length;

    if (turn.sixRollCount != actualSixCount) {
      _fail('sixRollCount لا يطابق عدد مرات ظهور الرقم 6 في سجل الرميات.');
    }

    // A third six cancels the turn and moves to the next player.
    // Such a turn is not a stable active-turn snapshot.
    if (turn.sixRollCount >= 3) {
      _fail('الدور يحتوي على ثلاث رميات 6 أو أكثر.');
    }

    if (turn.phase == TurnPhase.playing && turn.availableRolls.isEmpty) {
      _fail('مرحلة playing تتطلب وجود رمية متاحة واحدة على الأقل.');
    }

    // rolling may legitimately contain available rolls after a capture bonus.
  }

  void _validateRollHistory(TurnState turn) {
    for (var index = 0; index < turn.rolls.length; index++) {
      final roll = turn.rolls[index];
      final expectedSequence = index + 1;

      if (roll.value < 1 || roll.value > 6) {
        _fail('قيمة إحدى الرميات خارج النطاق من 1 إلى 6.');
      }

      if (roll.sequence != expectedSequence) {
        _fail('تسلسل سجل الرميات غير متتابع أو يحتوي على تكرار.');
      }
    }
  }

  void _validateAvailableRolls(TurnState turn) {
    final historyBySequence = {
      for (final roll in turn.rolls) roll.sequence: roll,
    };

    final availableSequences = <int>{};
    var previousSequence = 0;

    for (final availableRoll in turn.availableRolls.rolls) {
      if (!availableSequences.add(availableRoll.sequence)) {
        _fail('availableRolls تحتوي على sequence مكرر.');
      }

      // AvailableRolls preserves the original history order when rolls
      // are consumed, so remaining sequences must be ascending.
      if (availableRoll.sequence <= previousSequence) {
        _fail('ترتيب availableRolls غير متوافق مع سجل الرميات.');
      }

      previousSequence = availableRoll.sequence;

      final originalRoll = historyBySequence[availableRoll.sequence];

      if (originalRoll == null) {
        _fail('توجد رمية متاحة غير موجودة في سجل الرميات.');
      }

      if (originalRoll.value != availableRoll.value) {
        _fail('قيمة الرمية المتاحة لا تطابق الرمية الأصلية.');
      }
    }
  }

  Never _fail(String message) {
    throw StateError('Invalid match game snapshot: $message');
  }
}
