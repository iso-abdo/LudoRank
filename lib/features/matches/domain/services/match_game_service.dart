import 'dart:math';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/services/ludo_game_engine.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

import '../entities/match.dart';
import '../entities/match_status.dart';
import '../repositories/match_repository.dart';
import 'match_game_session.dart';
import 'match_points_calculator.dart';

/// Connects a persisted Match with the runtime LudoGameEngine.
///
/// Responsibilities:
/// - Load Match
/// - Load MatchPlayers
/// - Build runtime LudoPlayers
/// - Start LudoGameEngine
/// - Persist Match status
/// - Convert GameResult -> MatchPlayer rank/points
/// - Mark Match as finished
///
/// Explicitly NOT responsible for:
/// - Dice rules
/// - Token movement
/// - Capture rules
/// - Safe cells
/// - Home Lane
/// - Exact finish
/// - Turn rules
///
/// Those belong exclusively to LudoGameEngine.
class MatchGameService {
  final MatchRepository matchRepository;
  final MatchPlayerRepository matchPlayerRepository;
  final MatchPointsCalculator pointsCalculator;

  const MatchGameService({
    required this.matchRepository,
    required this.matchPlayerRepository,
    this.pointsCalculator = const MatchPointsCalculator(),
  });

  /// Starts a match and returns its runtime session.
  ///
  /// playerNames:
  ///     Key   = Player.id
  ///     Value = Player.name
  ///
  /// MatchPlayer intentionally does not own the display name,
  /// so the runtime layer receives it explicitly.
  Future<MatchGameSession> startMatch({
    required String matchId,
    required Map<String, String> playerNames,
    Random? random,
  }) async {
    final match = await matchRepository.getById(matchId);

    if (match == null) {
      throw StateError(
        'المباراة $matchId غير موجودة.',
      );
    }

    if (match.status != MatchStatus.pending) {
      throw StateError(
        'لا يمكن بدء المباراة إلا إذا كانت حالتها Pending.',
      );
    }

    final matchPlayers =
    await matchPlayerRepository.getMatchPlayers(matchId);

    _validateMatchPlayers(
      match: match,
      matchPlayers: matchPlayers,
      playerNames: playerNames,
    );

    final ludoPlayers = _buildLudoPlayers(
      matchPlayers: matchPlayers,
      playerNames: playerNames,
    );

    final initialState = LudoGameState.initial(
      players: ludoPlayers,
    );

    final engine = LudoGameEngine(
      initialState: initialState,
      random: random,
    );

    engine.startGame();

    final playingMatch = match.copyWith(
      status: MatchStatus.playing,
      updatedAt: DateTime.now(),
    );

    await matchRepository.update(
      playingMatch,
    );

    return MatchGameSession(
      match: playingMatch,
      matchPlayers: matchPlayers,
      engine: engine,
    );
  }

  /// Returns the current GameResult from the running session.
  ///
  /// This method does not persist anything.
  GameResult getResult(
      MatchGameSession session,
      ) {
    return session.result;
  }

  /// Completes a running match using the result produced by
  /// the current LudoGameEngine.
  ///
  /// The engine MUST already be finished.
  Future<List<MatchPlayer>> completeMatch(
      MatchGameSession session,
      ) async {
    if (!session.isFinished) {
      throw StateError(
        'لا يمكن إنهاء Match قبل انتهاء LudoGameEngine.',
      );
    }

    final result = session.result;

    return completeMatchFromResult(
      session: session,
      result: result,
    );
  }

  /// Persists an already completed GameResult.
  ///
  /// This method exists intentionally because it gives us a clean
  /// boundary between:
  ///
  /// LudoGameEngine
  ///     ↓
  /// GameResult
  ///     ↓
  /// MatchGameService
  ///
  /// It is also deterministic and easy to test.
  Future<List<MatchPlayer>> completeMatchFromResult({
    required MatchGameSession session,
    required GameResult result,
  }) async {
    if (!result.isFinished) {
      throw StateError(
        'GameResult ليس مكتملًا.',
      );
    }

   /// final match = session.match;

    ///if (match.status == MatchStatus.finished) {
     /// throw StateError(
       /// 'المباراة تم إنهاؤها بالفعل.',
     /// );
   /// }
    ///
    final match = await matchRepository.getById(
      session.match.id,
    );

    if (match == null) {
      throw StateError(
        'المباراة ${session.match.id} غير موجودة.',
      );
    }

    if (match.status != MatchStatus.playing) {
      throw StateError(
        'لا يمكن إنهاء المباراة إلا إذا كانت حالتها Playing.',
      );
    }

    final storedMatchPlayers =
    await matchPlayerRepository.getMatchPlayers(
      match.id,
    );

    _validateCompletedResult(
      match: match,
      matchPlayers: storedMatchPlayers,
      result: result,
    );

    final updatedPlayers = <MatchPlayer>[];

    for (final matchPlayer in storedMatchPlayers) {
      final playerResult =
      result.getPlayerResult(
        matchPlayer.playerId,
      );

      if (playerResult == null) {
        throw StateError(
          'لا توجد نتيجة للاعب ${matchPlayer.playerId}.',
        );
      }

      final points = pointsCalculator.calculate(
        playersCount: match.playersCount,
        rank: playerResult.rank,
      );

      updatedPlayers.add(
        matchPlayer.copyWith(
          rank: playerResult.rank,
          points: points,
          finished: playerResult.finished,
        ),
      );
    }

    await matchPlayerRepository.updateMatchPlayers(
      updatedPlayers,
    );

    final finishedMatch = match.copyWith(
      status: MatchStatus.finished,
      updatedAt: DateTime.now(),
    );

    await matchRepository.update(
      finishedMatch,
    );

    return List.unmodifiable(
      updatedPlayers,
    );
  }

  List<LudoPlayer> _buildLudoPlayers({
    required List<MatchPlayer> matchPlayers,
    required Map<String, String> playerNames,
  }) {
    final sortedPlayers = [...matchPlayers]
      ..sort(
            (a, b) => a.seat.compareTo(b.seat),
      );

    return sortedPlayers
        .map(
          (matchPlayer) => LudoPlayer(
        id: 'ludo-${matchPlayer.playerId}',
        playerId: matchPlayer.playerId,
        name: playerNames[matchPlayer.playerId]!,
        color: _colorForSeat(
          matchPlayer.seat,
        ),
        seat: matchPlayer.seat,
        tokens: _createInitialTokens(
          playerId: matchPlayer.playerId,
        ),
      ),
    )
        .toList(growable: false);
  }

  List<LudoToken> _createInitialTokens({
    required String playerId,
  }) {
    return List.generate(
      4,
          (index) => LudoToken(
        id: '$playerId-token-$index',
        playerId: playerId,
        tokenIndex: index,
        position: const Position(
          row: 0,
          column: 0,
        ),
        positionInPath: -1,
        state: LudoTokenState.initial,
      ),
      growable: false,
    );
  }

  LudoPlayerColor _colorForSeat(
      int seat,
      ) {
    switch (seat) {
      case 1:
        return LudoPlayerColor.green;

      case 2:
        return LudoPlayerColor.yellow;

      case 3:
        return LudoPlayerColor.blue;

      case 4:
        return LudoPlayerColor.red;

      default:
        throw ArgumentError(
          'Seat يجب أن يكون بين 1 و 4.',
        );
    }
  }

  void _validateMatchPlayers({
    required Match match,
    required List<MatchPlayer> matchPlayers,
    required Map<String, String> playerNames,
  }) {
    if (match.playersCount < 2 ||
        match.playersCount > 4) {
      throw StateError(
        'عدد لاعبي المباراة يجب أن يكون 2 أو 3 أو 4.',
      );
    }

    if (matchPlayers.length != match.playersCount) {
      throw StateError(
        'عدد MatchPlayers لا يطابق playersCount.',
      );
    }

    final playerIds = <String>{};
    final seats = <int>{};

    for (final matchPlayer in matchPlayers) {
      if (matchPlayer.matchId != match.id) {
        throw StateError(
          'MatchPlayer ${matchPlayer.id} ينتمي إلى Match مختلف.',
        );
      }

      if (!playerIds.add(
        matchPlayer.playerId,
      )) {
        throw StateError(
          'اللاعب ${matchPlayer.playerId} مكرر داخل المباراة.',
        );
      }

      if (matchPlayer.seat < 1 ||
          matchPlayer.seat > match.playersCount) {
        throw StateError(
          'Seat ${matchPlayer.seat} غير صالح لهذه المباراة.',
        );
      }

      if (!seats.add(
        matchPlayer.seat,
      )) {
        throw StateError(
          'Seat ${matchPlayer.seat} مكرر.',
        );
      }

      final name =
      playerNames[matchPlayer.playerId];

      if (name == null ||
          name.trim().isEmpty) {
        throw StateError(
          'لا يوجد اسم للاعب ${matchPlayer.playerId}.',
        );
      }
    }
  }

  void _validateCompletedResult({
    required Match match,
    required List<MatchPlayer> matchPlayers,
    required GameResult result,
  }) {
    if (matchPlayers.length != match.playersCount) {
      throw StateError(
        'عدد MatchPlayers لا يطابق عدد لاعبي Match.',
      );
    }

    if (result.players.length != match.playersCount) {
      throw StateError(
        'GameResult لا يحتوي على ترتيب كامل للاعبين.',
      );
    }

    if (!result.isFinished) {
      throw StateError(
        'GameResult غير مكتمل.',
      );
    }

    final expectedPlayerIds =
    matchPlayers.map(
          (player) => player.playerId,
    );

    final actualPlayerIds =
    result.players.map(
          (player) => player.playerId,
    );

    if (expectedPlayerIds.toSet().length !=
        actualPlayerIds.toSet().length) {
      throw StateError(
        'GameResult يحتوي على لاعبين مكررين.',
      );
    }

    if (!actualPlayerIds.toSet().containsAll(
      expectedPlayerIds,
    ) ||
        !expectedPlayerIds.toSet().containsAll(
          actualPlayerIds,
        )) {
      throw StateError(
        'GameResult لا يطابق لاعبي المباراة.',
      );
    }

    final ranks =
    result.players.map(
          (player) => player.rank,
    ).toSet();

    if (ranks.length != match.playersCount) {
      throw StateError(
        'رتب اللاعبين يجب أن تكون فريدة.',
      );
    }

    for (var rank = 1;
    rank <= match.playersCount;
    rank++) {
      if (!ranks.contains(rank)) {
        throw StateError(
          'الرتب يجب أن تبدأ من 1 وتنتهي عند ${match.playersCount}.',
        );
      }
    }

    for (final player in result.players) {
      if (!player.finished) {
        throw StateError(
          'كل لاعب في GameResult المكتمل يجب أن يكون Finished.',
        );
      }
    }
  }
}