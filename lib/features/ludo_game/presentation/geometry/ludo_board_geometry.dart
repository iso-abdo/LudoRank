import 'package:flutter/rendering.dart';

import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';
import 'package:ludo_rank/features/ludo_game/domain/constants/safe_cells.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';

enum LudoBoardCellKind { home, mainPath, safe, start, homeLane, finish, center }

class LudoBoardCell {
  final Position position;
  final LudoBoardCellKind kind;
  final LudoPlayerColor? ownerColor;

  const LudoBoardCell({
    required this.position,
    required this.kind,
    this.ownerColor,
  });

  bool get isHome => kind == LudoBoardCellKind.home;

  bool get isMainPath => kind == LudoBoardCellKind.mainPath;

  bool get isSafe =>
      kind == LudoBoardCellKind.safe || kind == LudoBoardCellKind.start;

  bool get isStart => kind == LudoBoardCellKind.start;

  bool get isHomeLane => kind == LudoBoardCellKind.homeLane;

  bool get isFinish => kind == LudoBoardCellKind.finish;

  bool get isCenter => kind == LudoBoardCellKind.center;
}

/// Geometry information used only by the presentation layer.
///
/// The domain remains the source of truth for:
/// - movement paths
/// - safe cells
/// - starting cells
/// - home lanes
/// - finish positions
///
/// This class only converts that information into board geometry.
class LudoBoardGeometry {
  const LudoBoardGeometry._();

  static const instance = LudoBoardGeometry._();

  // ============================================================
  // BOARD
  // ============================================================

  static const int gridSize = 15;

  // ============================================================
  // HOME ZONES
  // ============================================================

  static const Map<LudoPlayerColor, _GridRect> _homeZones = {
    LudoPlayerColor.green: _GridRect(row: 1, column: 1, size: 6),
    LudoPlayerColor.yellow: _GridRect(row: 1, column: 10, size: 6),
    LudoPlayerColor.red: _GridRect(row: 10, column: 1, size: 6),
    LudoPlayerColor.blue: _GridRect(row: 10, column: 10, size: 6),
  };

  // ============================================================
  // TOKEN HOME PADS
  // ============================================================

  static const Map<LudoPlayerColor, List<Position>> _tokenPads = {
    LudoPlayerColor.green: [
      Position(row: 2, column: 2),
      Position(row: 2, column: 5),
      Position(row: 5, column: 2),
      Position(row: 5, column: 5),
    ],
    LudoPlayerColor.yellow: [
      Position(row: 2, column: 11),
      Position(row: 2, column: 14),
      Position(row: 5, column: 11),
      Position(row: 5, column: 14),
    ],
    LudoPlayerColor.red: [
      Position(row: 11, column: 2),
      Position(row: 11, column: 5),
      Position(row: 14, column: 2),
      Position(row: 14, column: 5),
    ],
    LudoPlayerColor.blue: [
      Position(row: 11, column: 11),
      Position(row: 11, column: 14),
      Position(row: 14, column: 11),
      Position(row: 14, column: 14),
    ],
  };

  // ============================================================
  // DOMAIN-BASED POSITIONS
  // ============================================================

  static final Set<Position> _mainPathPositions = {
    ...LudoPaths.green.mainLoopPath,
  };

  static final Set<Position> _safePositions = {...SafeCells.all};

  static final Map<Position, LudoPlayerColor> _startOwners = {
    LudoPaths.green.startingPosition: LudoPlayerColor.green,
    LudoPaths.yellow.startingPosition: LudoPlayerColor.yellow,
    LudoPaths.blue.startingPosition: LudoPlayerColor.blue,
    LudoPaths.red.startingPosition: LudoPlayerColor.red,
  };

  static final Map<Position, LudoPlayerColor> _homeLaneOwners = {
    for (final entry in {
      LudoPlayerColor.green: LudoPaths.green.homePath,
      LudoPlayerColor.yellow: LudoPaths.yellow.homePath,
      LudoPlayerColor.blue: LudoPaths.blue.homePath,
      LudoPlayerColor.red: LudoPaths.red.homePath,
    }.entries)
      for (final position in entry.value.take(5)) position: entry.key,
  };

  static final Map<Position, LudoPlayerColor> _finishOwners = {
    LudoPaths.green.finishPosition: LudoPlayerColor.green,
    LudoPaths.yellow.finishPosition: LudoPlayerColor.yellow,
    LudoPaths.blue.finishPosition: LudoPlayerColor.blue,
    LudoPaths.red.finishPosition: LudoPlayerColor.red,
  };

  // ============================================================
  // ALL CELLS
  // ============================================================

  static final List<LudoBoardCell> _cells = List.unmodifiable(_buildCells());

  static List<LudoBoardCell> _buildCells() {
    final result = <LudoBoardCell>[];

    for (var row = 1; row <= gridSize; row++) {
      for (var column = 1; column <= gridSize; column++) {
        final position = Position(row: row, column: column);

        result.add(_classifyPosition(position));
      }
    }

    return result;
  }

  static LudoBoardCell _classifyPosition(Position position) {
    final homeOwner = _homeOwnerForPosition(position);

    if (homeOwner != null) {
      return LudoBoardCell(
        position: position,
        kind: LudoBoardCellKind.home,
        ownerColor: homeOwner,
      );
    }

    final finishOwner = _finishOwners[position];

    if (finishOwner != null) {
      return LudoBoardCell(
        position: position,
        kind: LudoBoardCellKind.finish,
        ownerColor: finishOwner,
      );
    }

    final homeLaneOwner = _homeLaneOwners[position];

    if (homeLaneOwner != null) {
      return LudoBoardCell(
        position: position,
        kind: LudoBoardCellKind.homeLane,
        ownerColor: homeLaneOwner,
      );
    }

    final startOwner = _startOwners[position];

    if (startOwner != null) {
      return LudoBoardCell(
        position: position,
        kind: LudoBoardCellKind.start,
        ownerColor: startOwner,
      );
    }

    if (_safePositions.contains(position)) {
      return LudoBoardCell(position: position, kind: LudoBoardCellKind.safe);
    }

    if (_mainPathPositions.contains(position)) {
      return LudoBoardCell(
        position: position,
        kind: LudoBoardCellKind.mainPath,
      );
    }

    return LudoBoardCell(position: position, kind: LudoBoardCellKind.center);
  }

  static LudoPlayerColor? _homeOwnerForPosition(Position position) {
    for (final entry in _homeZones.entries) {
      if (entry.value.contains(position)) {
        return entry.key;
      }
    }

    return null;
  }

  // ============================================================
  // PUBLIC DATA
  // ============================================================

  List<LudoBoardCell> get cells => _cells;

  List<Position> tokenPadsFor(LudoPlayerColor color) {
    return _tokenPads[color] ?? const <Position>[];
  }

  Position tokenHomePosition({
    required LudoPlayerColor color,
    required int tokenIndex,
  }) {
    if (tokenIndex < 0 || tokenIndex >= 4) {
      throw RangeError.range(tokenIndex, 0, 3, 'tokenIndex');
    }

    return _tokenPads[color]![tokenIndex];
  }

  LudoPlayerColor? ownerForStart(Position position) {
    return _startOwners[position];
  }

  LudoPlayerColor? ownerForHomeLane(Position position) {
    return _homeLaneOwners[position];
  }

  LudoPlayerColor? ownerForFinish(Position position) {
    return _finishOwners[position];
  }

  Set<Position> get safePositions {
    return Set.unmodifiable(_safePositions);
  }

  Set<Position> get startPositions {
    return Set.unmodifiable(_startOwners.keys);
  }

  Set<Position> get homeLanePositions {
    return Set.unmodifiable(_homeLaneOwners.keys);
  }

  Set<Position> get finishPositions {
    return Set.unmodifiable(_finishOwners.keys);
  }

  Set<Position> get centerPositions {
    return _cells
        .where((cell) => cell.kind == LudoBoardCellKind.center)
        .map((cell) => cell.position)
        .toSet();
  }

  // ============================================================
  // BOARD VALIDATION
  // ============================================================

  bool isInside(Position position) {
    return position.row >= 1 &&
        position.row <= gridSize &&
        position.column >= 1 &&
        position.column <= gridSize;
  }

  // ============================================================
  // PIXEL GEOMETRY
  // ============================================================

  double cellSize(double boardWidth) {
    return boardWidth / gridSize;
  }

  Rect cellRect(Position position, double boardWidth) {
    if (!isInside(position)) {
      throw RangeError(
        'Position خارج اللوحة: '
        '${position.row}, ${position.column}',
      );
    }

    final size = cellSize(boardWidth);

    final rowIndex = position.row - 1;
    final columnIndex = position.column - 1;

    return Rect.fromLTWH(columnIndex * size, rowIndex * size, size, size);
  }

  Offset cellCenter(Position position, double boardWidth) {
    return cellRect(position, boardWidth).center;
  }

  Rect homeZoneRect(LudoPlayerColor color, double boardWidth) {
    final zone = _homeZones[color];

    if (zone == null) {
      throw StateError('لا توجد Home Zone للون $color.');
    }

    final size = cellSize(boardWidth);

    return Rect.fromLTWH(
      (zone.column - 1) * size,
      (zone.row - 1) * size,
      zone.size * size,
      zone.size * size,
    );
  }

  // ============================================================
  // CENTER
  // ============================================================

  static const Position centerPosition = Position(row: 8, column: 8);
}

class _GridRect {
  final int row;
  final int column;
  final int size;

  const _GridRect({
    required this.row,
    required this.column,
    required this.size,
  });

  bool contains(Position position) {
    return position.row >= row &&
        position.row < row + size &&
        position.column >= column &&
        position.column < column + size;
  }
}
