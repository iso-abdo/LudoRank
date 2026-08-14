class Position {
  final int row;
  final int column;

  const Position({
    required this.row,
    required this.column,
  });

  Position copyWith({
    int? row,
    int? column,
  }) {
    return Position(
      row: row ?? this.row,
      column: column ?? this.column,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Position &&
        other.row == row &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}