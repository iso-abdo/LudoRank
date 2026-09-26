import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';

import '../geometry/ludo_board_geometry.dart';

class LudoBoard extends StatelessWidget {
  final List<LudoPlayer> players;
  final List<MoveOption> availableMoves;
  final String? selectedTokenId;

  final ValueChanged<LudoToken>? onTokenTap;

  const LudoBoard({
    super.key,
    required this.players,
    this.availableMoves = const <MoveOption>[],
    this.selectedTokenId,
    this.onTokenTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LudoBoardPainter(
                      geometry: LudoBoardGeometry.instance,
                    ),
                  ),
                ),
                ..._buildTokens(boardSize),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TOKENS
  // ============================================================

  List<Widget> _buildTokens(double boardSize) {
    final geometry = LudoBoardGeometry.instance;

    final groupedTokens = <PositionKey, List<_VisualToken>>{};

    for (final player in players) {
      for (final token in player.tokens) {
        final visualPosition = token.isInitial
            ? geometry.tokenHomePosition(
                color: player.color,
                tokenIndex: token.tokenIndex,
              )
            : token.position;

        final key = PositionKey(
          row: visualPosition.row,
          column: visualPosition.column,
        );

        groupedTokens
            .putIfAbsent(key, () => <_VisualToken>[])
            .add(
              _VisualToken(
                token: token,
                color: player.color,
                position: visualPosition,
              ),
            );
      }
    }

    final widgets = <Widget>[];

    for (final group in groupedTokens.values) {
      for (var index = 0; index < group.length; index++) {
        final visualToken = group[index];

        final tokenSize = _tokenSize(boardSize);

        final center = geometry.cellCenter(visualToken.position, boardSize);

        final offset = _stackOffset(
          index: index,
          count: group.length,
          boardSize: boardSize,
        );

        widgets.add(
          Positioned(
            left: center.dx - tokenSize / 2 + offset.dx,
            top: center.dy - tokenSize / 2 + offset.dy,
            width: tokenSize,
            height: tokenSize,
            child: _LudoBoardToken(
              token: visualToken.token,
              color: visualToken.color,
              isSelected: visualToken.token.id == selectedTokenId,
              isMovable: _isTokenMovable(visualToken.token.id),
              onTap: onTokenTap == null
                  ? null
                  : () {
                      onTokenTap!(visualToken.token);
                    },
            ),
          ),
        );
      }
    }

    return widgets;
  }

  bool _isTokenMovable(String tokenId) {
    for (final move in availableMoves) {
      if (move is MoveToken && move.tokenId == tokenId) {
        return true;
      }

      if (move is ExitToken && move.tokenId == tokenId) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // TOKEN SIZE
  // ============================================================

  double _tokenSize(double boardSize) {
    return boardSize / LudoBoardGeometry.gridSize * 0.72;
  }

  // ============================================================
  // BLOCK STACKING
  // ============================================================

  Offset _stackOffset({
    required int index,
    required int count,
    required double boardSize,
  }) {
    final cellSize = boardSize / LudoBoardGeometry.gridSize;

    if (count <= 1) {
      return Offset.zero;
    }

    if (count == 2) {
      const positions = <Offset>[Offset(-0.18, -0.18), Offset(0.18, 0.18)];

      return positions[index] * cellSize;
    }

    if (count == 3) {
      const positions = <Offset>[
        Offset(-0.18, -0.16),
        Offset(0.18, -0.16),
        Offset(0, 0.18),
      ];

      return positions[index] * cellSize;
    }

    const positions = <Offset>[
      Offset(-0.17, -0.17),
      Offset(0.17, -0.17),
      Offset(-0.17, 0.17),
      Offset(0.17, 0.17),
    ];

    final safeIndex = index.clamp(0, positions.length - 1);

    return positions[safeIndex] * cellSize;
  }
}

// ==================================================================
// VISUAL TOKEN
// ==================================================================

class _VisualToken {
  final LudoToken token;
  final LudoPlayerColor color;
  final Position position;

  const _VisualToken({
    required this.token,
    required this.color,
    required this.position,
  });
}

// ==================================================================
// POSITION KEY
// ==================================================================

class PositionKey {
  final int row;
  final int column;

  const PositionKey({required this.row, required this.column});

  @override
  bool operator ==(Object other) {
    return other is PositionKey && other.row == row && other.column == column;
  }

  @override
  int get hashCode {
    return Object.hash(row, column);
  }
}

// ==================================================================
// TOKEN WIDGET
// ==================================================================

class _LudoBoardToken extends StatelessWidget {
  final LudoToken token;
  final LudoPlayerColor color;

  final bool isSelected;
  final bool isMovable;

  final VoidCallback? onTap;

  const _LudoBoardToken({
    required this.token,
    required this.color,
    required this.isSelected,
    required this.isMovable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = _colorFor(color);

    final child = AnimatedScale(
      scale: isSelected ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            radius: 0.95,
            colors: [
              baseColor.withValues(alpha: 0.95),
              baseColor.withValues(alpha: 0.72),
            ],
          ),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : baseColor.withValues(alpha: 0.35),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: isSelected ? 10 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isMovable)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  Color _colorFor(LudoPlayerColor color) {
    switch (color) {
      case LudoPlayerColor.green:
        return const Color(0xFF20B26B);

      case LudoPlayerColor.yellow:
        return const Color(0xFFF2B705);

      case LudoPlayerColor.blue:
        return const Color(0xFF4285F4);

      case LudoPlayerColor.red:
        return const Color(0xFFE94B4B);
    }
  }
}

// ==================================================================
// BOARD PAINTER
// ==================================================================

class _LudoBoardPainter extends CustomPainter {
  final LudoBoardGeometry geometry;

  const _LudoBoardPainter({required this.geometry});

  @override
  void paint(Canvas canvas, Size size) {
    final boardWidth = math.min(size.width, size.height);

    final cellSize = boardWidth / LudoBoardGeometry.gridSize;

    final boardRect = Rect.fromLTWH(0, 0, boardWidth, boardWidth);

    // ==========================================================
    // BACKGROUND
    // ==========================================================

    canvas.drawRect(boardRect, Paint()..color = const Color(0xFFF4F5F7));

    // ==========================================================
    // HOME ZONES
    // ==========================================================

    for (final color in LudoPlayerColor.values) {
      final rect = geometry.homeZoneRect(color, boardWidth);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(cellSize * 0.08),
          Radius.circular(cellSize * 0.45),
        ),
        Paint()..color = _colorFor(color).withValues(alpha: 0.11),
      );
    }

    // ==========================================================
    // CELLS
    // ==========================================================

    for (final cell in geometry.cells) {
      final rect = geometry.cellRect(cell.position, boardWidth);

      _paintCell(canvas, rect, cell);
    }

    // ==========================================================
    // TOKEN HOME PADS
    // ==========================================================

    for (final color in LudoPlayerColor.values) {
      for (final position in geometry.tokenPadsFor(color)) {
        final center = geometry.cellCenter(position, boardWidth);

        canvas.drawCircle(
          center,
          cellSize * 0.28,
          Paint()..color = Colors.white.withValues(alpha: 0.65),
        );

        canvas.drawCircle(
          center,
          cellSize * 0.28,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = _colorFor(color).withValues(alpha: 0.20),
        );
      }
    }

    // ==========================================================
    // CENTER
    // ==========================================================

    _paintCenter(canvas, boardWidth);

    // ==========================================================
    // GRID
    // ==========================================================

    final gridPaint = Paint()
      ..color = const Color(0xFFD9DDE3)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= LudoBoardGeometry.gridSize; i++) {
      final offset = i * cellSize;

      canvas.drawLine(Offset(offset, 0), Offset(offset, boardWidth), gridPaint);

      canvas.drawLine(Offset(0, offset), Offset(boardWidth, offset), gridPaint);
    }

    // ==========================================================
    // BORDER
    // ==========================================================

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        boardRect.deflate(1),
        Radius.circular(cellSize * 0.16),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFCDD2D9),
    );
  }

  // ============================================================
  // CELL PAINT
  // ============================================================

  void _paintCell(Canvas canvas, Rect rect, LudoBoardCell cell) {
    switch (cell.kind) {
      case LudoBoardCellKind.home:
        _paintHomeCell(canvas, rect, cell.ownerColor!);

      case LudoBoardCellKind.mainPath:
        _paintRoadCell(canvas, rect);

      case LudoBoardCellKind.safe:
        _paintSafeCell(canvas, rect);

      case LudoBoardCellKind.start:
        _paintStartCell(canvas, rect, cell.ownerColor!);

      case LudoBoardCellKind.homeLane:
        _paintHomeLaneCell(canvas, rect, cell.ownerColor!);

      case LudoBoardCellKind.finish:
        _paintFinishCell(canvas, rect, cell.ownerColor!);

      case LudoBoardCellKind.center:
        _paintCenterCell(canvas, rect);
    }
  }

  // ============================================================
  // HOME
  // ============================================================

  void _paintHomeCell(Canvas canvas, Rect rect, LudoPlayerColor color) {
    canvas.drawRect(
      rect,
      Paint()..color = _colorFor(color).withValues(alpha: 0.025),
    );
  }

  // ============================================================
  // ROAD
  // ============================================================

  void _paintRoadCell(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = Colors.white);
  }

  // ============================================================
  // SAFE
  // ============================================================

  void _paintSafeCell(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF7F8FA));

    _paintStar(canvas, rect.center, rect.width * 0.20);
  }

  // ============================================================
  // START
  // ============================================================

  void _paintStartCell(Canvas canvas, Rect rect, LudoPlayerColor color) {
    final base = _colorFor(color);

    canvas.drawRect(rect, Paint()..color = base.withValues(alpha: 0.20));

    canvas.drawCircle(
      rect.center,
      rect.width * 0.27,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = base,
    );

    canvas.drawCircle(rect.center, rect.width * 0.08, Paint()..color = base);
  }

  // ============================================================
  // HOME LANE
  // ============================================================

  void _paintHomeLaneCell(Canvas canvas, Rect rect, LudoPlayerColor color) {
    canvas.drawRect(
      rect,
      Paint()..color = _colorFor(color).withValues(alpha: 0.24),
    );
  }

  // ============================================================
  // FINISH
  // ============================================================

  void _paintFinishCell(Canvas canvas, Rect rect, LudoPlayerColor color) {
    final base = _colorFor(color);

    canvas.drawRect(rect, Paint()..color = base.withValues(alpha: 0.70));

    canvas.drawCircle(
      rect.center,
      rect.width * 0.19,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  // ============================================================
  // CENTER CELL
  // ============================================================

  void _paintCenterCell(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFFE7E9ED));
  }

  // ============================================================
  // CENTER ART
  // ============================================================

  void _paintCenter(Canvas canvas, double boardWidth) {
    final cellSize = boardWidth / LudoBoardGeometry.gridSize;

    final start = 6 * cellSize;

    final end = 9 * cellSize;

    final centerRect = Rect.fromLTRB(start, start, end, end);

    final center = centerRect.center;

    final top = Offset(center.dx, centerRect.top);

    final right = Offset(centerRect.right, center.dy);

    final bottom = Offset(center.dx, centerRect.bottom);

    final left = Offset(centerRect.left, center.dy);

    final slices = [
      _TriangleSlice(
        color: _colorFor(LudoPlayerColor.yellow),
        a: top,
        b: right,
        center: center,
      ),
      _TriangleSlice(
        color: _colorFor(LudoPlayerColor.blue),
        a: right,
        b: bottom,
        center: center,
      ),
      _TriangleSlice(
        color: _colorFor(LudoPlayerColor.red),
        a: bottom,
        b: left,
        center: center,
      ),
      _TriangleSlice(
        color: _colorFor(LudoPlayerColor.green),
        a: left,
        b: top,
        center: center,
      ),
    ];

    for (final slice in slices) {
      final path = Path()
        ..moveTo(slice.center.dx, slice.center.dy)
        ..lineTo(slice.a.dx, slice.a.dy)
        ..lineTo(slice.b.dx, slice.b.dy)
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = slice.color.withValues(alpha: 0.72),
      );
    }

    canvas.drawCircle(
      center,
      cellSize * 0.21,
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );

    canvas.drawCircle(
      center,
      cellSize * 0.12,
      Paint()..color = const Color(0xFF3C4148),
    );
  }

  // ============================================================
  // STAR
  // ============================================================

  void _paintStar(Canvas canvas, Offset center, double radius) {
    final path = Path();

    const pointCount = 5;
    final innerRadius = radius * 0.42;

    for (var i = 0; i < pointCount * 2; i++) {
      final currentRadius = i.isEven ? radius : innerRadius;

      final angle = -math.pi / 2 + i * math.pi / pointCount;

      final point = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF6B7280));
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color _colorFor(LudoPlayerColor color) {
    switch (color) {
      case LudoPlayerColor.green:
        return const Color(0xFF20B26B);

      case LudoPlayerColor.yellow:
        return const Color(0xFFF2B705);

      case LudoPlayerColor.blue:
        return const Color(0xFF4285F4);

      case LudoPlayerColor.red:
        return const Color(0xFFE94B4B);
    }
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter oldDelegate) {
    return false;
  }
}

// ==================================================================
// CENTER TRIANGLE
// ==================================================================

class _TriangleSlice {
  final Color color;
  final Offset a;
  final Offset b;
  final Offset center;

  const _TriangleSlice({
    required this.color,
    required this.a,
    required this.b,
    required this.center,
  });
}
