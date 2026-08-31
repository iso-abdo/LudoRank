import '../entities/position.dart';

class SafeCells {
  const SafeCells._();

  static const List<Position> all = [
    // Starting Cells
    Position(row: 14, column: 7),
    Position(row: 7, column: 2),
    Position(row: 2, column: 9),
    Position(row: 9, column: 14),

    // Star / Safe Cells
    Position(row: 9, column: 3),
    Position(row: 3, column: 7),
    Position(row: 7, column: 13),
    Position(row: 8, column: 15),
  ];

  static bool contains(Position position) {
    return all.contains(position);
  }
}