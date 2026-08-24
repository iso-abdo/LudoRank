import 'package:equatable/equatable.dart';

class GameResult extends Equatable {
  /// ترتيب اللاعبين الذين أنهوا اللعبة.
  ///
  /// الترتيب يبدأ من 1.
  ///
  /// مثال:
  /// rank 1 = أول لاعب أنهى اللعبة
  /// rank 2 = ثاني لاعب
  /// rank 3 = ثالث لاعب
  /// rank 4 = رابع لاعب
  final List<GamePlayerResult> players;

  /// هل المباراة انتهت بالكامل؟
  ///
  /// true عندما لا يوجد لاعبون غير منتهين.
  final bool isFinished;

  const GameResult({
    required this.players,
    required this.isFinished,
  });

  /// نتيجة لاعب واحد حسب الترتيب.
  GamePlayerResult? getPlayerResult(String playerId) {
    for (final result in players) {
      if (result.playerId == playerId) {
        return result;
      }
    }

    return null;
  }

  /// عدد اللاعبين الذين حصلوا على ترتيب.
  int get rankedPlayersCount => players.length;

  @override
  List<Object?> get props => [
    players,
    isFinished,
  ];
}

class GamePlayerResult extends Equatable {
  /// ID اللاعب من LudoRank.
  final String playerId;

  /// ترتيب اللاعب في اللعبة.
  ///
  /// 1 = الأول
  /// 2 = الثاني
  /// 3 = الثالث
  /// ...
  final int rank;

  /// هل اللاعب أنهى اللعبة فعليًا؟
  final bool finished;

  const GamePlayerResult({
    required this.playerId,
    required this.rank,
    required this.finished,
  });

  @override
  List<Object?> get props => [
    playerId,
    rank,
    finished,
  ];
}