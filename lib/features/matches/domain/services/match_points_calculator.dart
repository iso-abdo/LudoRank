/// Calculates tournament points from the final rank of a match.
///
/// Rule:
///
/// points = playersCount - rank + 1
///
/// Examples:
///
/// 4 players:
/// rank 1 => 4 points
/// rank 2 => 3 points
/// rank 3 => 2 points
/// rank 4 => 1 point
///
/// 3 players:
/// rank 1 => 3 points
/// rank 2 => 2 points
/// rank 3 => 1 point
///
/// 2 players:
/// rank 1 => 2 points
/// rank 2 => 1 point
class MatchPointsCalculator {
  const MatchPointsCalculator();

  int calculate({
    required int playersCount,
    required int rank,
  }) {
    _validatePlayersCount(playersCount);
    _validateRank(
      playersCount: playersCount,
      rank: rank,
    );

    return playersCount - rank + 1;
  }

  Map<int, int> calculateAll({
    required int playersCount,
  }) {
    _validatePlayersCount(playersCount);

    final result = <int, int>{};

    for (var rank = 1; rank <= playersCount; rank++) {
      result[rank] = calculate(
        playersCount: playersCount,
        rank: rank,
      );
    }

    return Map.unmodifiable(result);
  }

  void _validatePlayersCount(int playersCount) {
    if (playersCount < 2 || playersCount > 4) {
      throw ArgumentError(
        'عدد لاعبي المباراة يجب أن يكون 2 أو 3 أو 4.',
      );
    }
  }

  void _validateRank({
    required int playersCount,
    required int rank,
  }) {
    if (rank < 1 || rank > playersCount) {
      throw ArgumentError(
        'رتبة اللاعب يجب أن تكون بين 1 و $playersCount.',
      );
    }
  }
}