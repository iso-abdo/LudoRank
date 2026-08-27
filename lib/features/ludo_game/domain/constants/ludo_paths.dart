import '../entities/ludo_player.dart';
import '../entities/position.dart';

class LudoPath {
  final List<Position> positions;

  static const int mainLoopLength = 51;
  static const int homeLaneStartIndex = 51;
  static const int finishIndex = 56;

  const LudoPath({
    required this.positions,
  });

  Position operator [](int index) => positions[index];

  int get length => positions.length;

  bool get isEmpty => positions.isEmpty;

  bool get isNotEmpty => positions.isNotEmpty;

  Position get first => positions.first;

  Position get last => positions.last;

  List<Position> get mainLoop {
    return positions.sublist(
      0,
      homeLaneStartIndex,
    );
  }

  List<Position> get homeLane {
    return positions.sublist(
      homeLaneStartIndex,
    );
  }

  bool isInMainLoop(int index) {
    return index >= 0 &&
        index < homeLaneStartIndex;
  }

  bool isInHomeLane(int index) {
    return index >= homeLaneStartIndex &&
        index <= finishIndex;
  }

  bool isFinish(int index) {
    return index == finishIndex;
  }
}

class LudoPaths {
  const LudoPaths._();

  static const green = LudoPath(
    positions: [
      Position(row: 6, column: 1),
      Position(row: 6, column: 2),
      Position(row: 6, column: 3),
      Position(row: 6, column: 4),
      Position(row: 6, column: 5),
      Position(row: 5, column: 6),
      Position(row: 4, column: 6),
      Position(row: 3, column: 6),
      Position(row: 2, column: 6),
      Position(row: 1, column: 6),
      Position(row: 0, column: 6),
      Position(row: 0, column: 7),
      Position(row: 0, column: 8),
      Position(row: 1, column: 8),
      Position(row: 2, column: 8),
      Position(row: 3, column: 8),
      Position(row: 4, column: 8),
      Position(row: 5, column: 8),
      Position(row: 6, column: 9),
      Position(row: 6, column: 10),
      Position(row: 6, column: 11),
      Position(row: 6, column: 12),
      Position(row: 6, column: 13),
      Position(row: 6, column: 14),
      Position(row: 7, column: 14),
      Position(row: 8, column: 14),
      Position(row: 8, column: 13),
      Position(row: 8, column: 12),
      Position(row: 8, column: 11),
      Position(row: 8, column: 10),
      Position(row: 8, column: 9),
      Position(row: 9, column: 8),
      Position(row: 10, column: 8),
      Position(row: 11, column: 8),
      Position(row: 12, column: 8),
      Position(row: 13, column: 8),
      Position(row: 14, column: 8),
      Position(row: 14, column: 7),
      Position(row: 14, column: 6),
      Position(row: 13, column: 6),
      Position(row: 12, column: 6),
      Position(row: 11, column: 6),
      Position(row: 10, column: 6),
      Position(row: 9, column: 6),
      Position(row: 8, column: 5),
      Position(row: 8, column: 4),
      Position(row: 8, column: 3),
      Position(row: 8, column: 2),
      Position(row: 8, column: 1),
      Position(row: 8, column: 0),
      Position(row: 7, column: 0),
      Position(row: 7, column: 1),
      Position(row: 7, column: 2),
      Position(row: 7, column: 3),
      Position(row: 7, column: 4),
      Position(row: 7, column: 5),
      Position(row: 7, column: 6),
    ],
  );

  static const yellow = LudoPath(
    positions: [
      Position(row: 1, column: 8),
      Position(row: 2, column: 8),
      Position(row: 3, column: 8),
      Position(row: 4, column: 8),
      Position(row: 5, column: 8),
      Position(row: 6, column: 9),
      Position(row: 6, column: 10),
      Position(row: 6, column: 11),
      Position(row: 6, column: 12),
      Position(row: 6, column: 13),
      Position(row: 6, column: 14),
      Position(row: 7, column: 14),
      Position(row: 8, column: 14),
      Position(row: 8, column: 13),
      Position(row: 8, column: 12),
      Position(row: 8, column: 11),
      Position(row: 8, column: 10),
      Position(row: 8, column: 9),
      Position(row: 9, column: 8),
      Position(row: 10, column: 8),
      Position(row: 11, column: 8),
      Position(row: 12, column: 8),
      Position(row: 13, column: 8),
      Position(row: 14, column: 8),
      Position(row: 14, column: 7),
      Position(row: 14, column: 6),
      Position(row: 13, column: 6),
      Position(row: 12, column: 6),
      Position(row: 11, column: 6),
      Position(row: 10, column: 6),
      Position(row: 9, column: 6),
      Position(row: 8, column: 5),
      Position(row: 8, column: 4),
      Position(row: 8, column: 3),
      Position(row: 8, column: 2),
      Position(row: 8, column: 1),
      Position(row: 8, column: 0),
      Position(row: 7, column: 0),
      Position(row: 6, column: 0),
      Position(row: 6, column: 1),
      Position(row: 6, column: 2),
      Position(row: 6, column: 3),
      Position(row: 6, column: 4),
      Position(row: 6, column: 5),
      Position(row: 5, column: 6),
      Position(row: 4, column: 6),
      Position(row: 3, column: 6),
      Position(row: 2, column: 6),
      Position(row: 1, column: 6),
      Position(row: 0, column: 6),
      Position(row: 0, column: 7),
      Position(row: 1, column: 7),
      Position(row: 2, column: 7),
      Position(row: 3, column: 7),
      Position(row: 4, column: 7),
      Position(row: 5, column: 7),
      Position(row: 6, column: 7),
    ],
  );

  static const blue = LudoPath(
    positions: [
      Position(row: 8, column: 13),
      Position(row: 8, column: 12),
      Position(row: 8, column: 11),
      Position(row: 8, column: 10),
      Position(row: 8, column: 9),
      Position(row: 9, column: 8),
      Position(row: 10, column: 8),
      Position(row: 11, column: 8),
      Position(row: 12, column: 8),
      Position(row: 13, column: 8),
      Position(row: 14, column: 8),
      Position(row: 14, column: 7),
      Position(row: 14, column: 6),
      Position(row: 13, column: 6),
      Position(row: 12, column: 6),
      Position(row: 11, column: 6),
      Position(row: 10, column: 6),
      Position(row: 9, column: 6),
      Position(row: 8, column: 5),
      Position(row: 8, column: 4),
      Position(row: 8, column: 3),
      Position(row: 8, column: 2),
      Position(row: 8, column: 1),
      Position(row: 8, column: 0),
      Position(row: 7, column: 0),
      Position(row: 6, column: 0),
      Position(row: 6, column: 1),
      Position(row: 6, column: 2),
      Position(row: 6, column: 3),
      Position(row: 6, column: 4),
      Position(row: 6, column: 5),
      Position(row: 5, column: 6),
      Position(row: 4, column: 6),
      Position(row: 3, column: 6),
      Position(row: 2, column: 6),
      Position(row: 1, column: 6),
      Position(row: 0, column: 6),
      Position(row: 0, column: 7),
      Position(row: 0, column: 8),
      Position(row: 1, column: 8),
      Position(row: 2, column: 8),
      Position(row: 3, column: 8),
      Position(row: 4, column: 8),
      Position(row: 5, column: 8),
      Position(row: 6, column: 9),
      Position(row: 6, column: 10),
      Position(row: 6, column: 11),
      Position(row: 6, column: 12),
      Position(row: 6, column: 13),
      Position(row: 6, column: 14),
      Position(row: 7, column: 14),
      Position(row: 8, column: 14),
      Position(row: 8, column: 13),
      Position(row: 7, column: 13),
      Position(row: 7, column: 12),
      Position(row: 7, column: 11),
      Position(row: 7, column: 10),
      Position(row: 7, column: 9),
      Position(row: 7, column: 8),
    ],
  );

  static const red = LudoPath(
    positions: [
      Position(row: 13, column: 6),
      Position(row: 12, column: 6),
      Position(row: 11, column: 6),
      Position(row: 10, column: 6),
      Position(row: 9, column: 6),
      Position(row: 8, column: 5),
      Position(row: 8, column: 4),
      Position(row: 8, column: 3),
      Position(row: 8, column: 2),
      Position(row: 8, column: 1),
      Position(row: 8, column: 0),
      Position(row: 7, column: 0),
      Position(row: 6, column: 0),
      Position(row: 6, column: 1),
      Position(row: 6, column: 2),
      Position(row: 6, column: 3),
      Position(row: 6, column: 4),
      Position(row: 6, column: 5),
      Position(row: 5, column: 6),
      Position(row: 4, column: 6),
      Position(row: 3, column: 6),
      Position(row: 2, column: 6),
      Position(row: 1, column: 6),
      Position(row: 0, column: 6),
      Position(row: 0, column: 7),
      Position(row: 0, column: 8),
      Position(row: 1, column: 8),
      Position(row: 2, column: 8),
      Position(row: 3, column: 8),
      Position(row: 4, column: 8),
      Position(row: 5, column: 8),
      Position(row: 6, column: 9),
      Position(row: 6, column: 10),
      Position(row: 6, column: 11),
      Position(row: 6, column: 12),
      Position(row: 6, column: 13),
      Position(row: 6, column: 14),
      Position(row: 7, column: 14),
      Position(row: 8, column: 14),
      Position(row: 8, column: 13),
      Position(row: 8, column: 12),
      Position(row: 8, column: 11),
      Position(row: 8, column: 10),
      Position(row: 8, column: 9),
      Position(row: 9, column: 8),
      Position(row: 10, column: 8),
      Position(row: 11, column: 8),
      Position(row: 12, column: 8),
      Position(row: 13, column: 8),
      Position(row: 14, column: 8),
      Position(row: 14, column: 7),
      Position(row: 13, column: 7),
      Position(row: 12, column: 7),
      Position(row: 11, column: 7),
      Position(row: 10, column: 7),
      Position(row: 9, column: 7),
      Position(row: 8, column: 7),
    ],
  );

  static LudoPath forColor(
      LudoPlayerColor color,
      ) {
    switch (color) {
      case LudoPlayerColor.green:
        return green;

      case LudoPlayerColor.yellow:
        return yellow;

      case LudoPlayerColor.blue:
        return blue;

      case LudoPlayerColor.red:
        return red;
    }
  }
}