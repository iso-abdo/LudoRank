import '../entities/position.dart';

class SafeCells {
  const SafeCells._();

  static const List<Position> all = [
    Position(row: 6, column: 1),
    Position(row: 2, column: 6),
    Position(row: 1, column: 8),
    Position(row: 6, column: 12),
    Position(row: 8, column: 13),
    Position(row: 12, column: 8),
    Position(row: 13, column: 6),
    Position(row: 8, column: 2),
  ];

  static bool contains(Position position) {
    return all.contains(position);
  }
}