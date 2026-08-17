import 'package:equatable/equatable.dart';

import '../entities/ludo_player.dart';
import 'turn_state.dart';

class LudoGameState extends Equatable {
  /// لاعبو لعبة Ludo.
  final List<LudoPlayer> players;

  /// Index اللاعب صاحب الدور الحالي.
  final int currentPlayerIndex;

  /// حالة الدور الحالي بالكامل.
  final TurnState turnState;

  /// هل اللعبة بدأت؟
  final bool isStarted;

  /// هل اللعبة انتهت؟
  final bool isFinished;

  /// IDs اللاعبين الذين أنهوا اللعبة بالترتيب.
  ///
  /// مثال:
  ///
  /// [
  ///   'player-c',
  ///   'player-a',
  ///   'player-d',
  /// ]
  ///
  /// معناها:
  /// C = Rank 1
  /// A = Rank 2
  /// D = Rank 3
  final List<String> finishedPlayerIds;

  const LudoGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.turnState,
    this.isStarted = false,
    this.isFinished = false,
    this.finishedPlayerIds = const [],
  });

  /// الحالة الأولية للعبة.
  factory LudoGameState.initial({
    required List<LudoPlayer> players,
  }) {
    if (players.isEmpty) {
      throw ArgumentError(
        'يجب أن تحتوي اللعبة على لاعب واحد على الأقل.',
      );
    }

    final sortedPlayers = [...players]
      ..sort(
            (a, b) => a.seat.compareTo(b.seat),
      );

    return LudoGameState(
      players: List.unmodifiable(sortedPlayers),
      currentPlayerIndex: 0,
      turnState: TurnState.initial(
        sortedPlayers.first.playerId,
      ),
      isStarted: false,
      isFinished: false,
      finishedPlayerIds: const [],
    );
  }

  /// اللاعب صاحب الدور الحالي.
  LudoPlayer get currentPlayer {
    return players[currentPlayerIndex];
  }

  /// عدد اللاعبين.
  int get playersCount => players.length;

  /// عدد اللاعبين الذين أنهوا اللعبة.
  int get finishedPlayersCount {
    return finishedPlayerIds.length;
  }

  /// هل ما زال هناك لاعبون لم ينهوا اللعبة؟
  bool get hasUnfinishedPlayers {
    return finishedPlayerIds.length < players.length;
  }

  /// هل اللاعب الحالي أنهى اللعبة؟
  bool get currentPlayerFinished {
    return finishedPlayerIds.contains(
      currentPlayer.playerId,
    );
  }

  /// ترتيب لاعب أنهى اللعبة.
  ///
  /// أول لاعب = 1
  /// ثاني لاعب = 2
  /// ...
  int? getRankForPlayer(String playerId) {
    final index = finishedPlayerIds.indexOf(
      playerId,
    );

    if (index == -1) {
      return null;
    }

    return index + 1;
  }

  /// البحث عن لاعب بالـ playerId.
  LudoPlayer? getPlayerById(String playerId) {
    try {
      return players.firstWhere(
            (player) => player.playerId == playerId,
      );
    } catch (_) {
      return null;
    }
  }

  LudoGameState copyWith({
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    TurnState? turnState,
    bool? isStarted,
    bool? isFinished,
    List<String>? finishedPlayerIds,
  }) {
    return LudoGameState(
      players: List.unmodifiable(
        players ?? this.players,
      ),
      currentPlayerIndex:
      currentPlayerIndex ?? this.currentPlayerIndex,
      turnState:
      turnState ?? this.turnState,
      isStarted:
      isStarted ?? this.isStarted,
      isFinished:
      isFinished ?? this.isFinished,
      finishedPlayerIds: List.unmodifiable(
        finishedPlayerIds ??
            this.finishedPlayerIds,
      ),
    );
  }

  @override
  List<Object?> get props => [
    players,
    currentPlayerIndex,
    turnState,
    isStarted,
    isFinished,
    finishedPlayerIds,
  ];
}