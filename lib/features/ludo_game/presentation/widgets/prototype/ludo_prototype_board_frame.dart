import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/presentation/geometry/ludo_board_geometry.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/prototype/prototype_ludo_colors.dart';

/// Prototype-only visual board treatment.
///
/// It reuses the existing board geometry and domain paths for exact locations,
/// while reproducing the stronger home quadrants, recessed home pads, bold
/// colored lanes, circular token medallions and four-triangle center from the
/// supplied reference. No engine state or game rule is changed here.
class LudoPrototypeBoardFrame extends StatelessWidget {
  final List<LudoPlayer> players;

  const LudoPrototypeBoardFrame({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final frame = (side * .031).clamp(7.0, 11.0).toDouble();
        final innerSide = side - frame * 2;

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(side * .045),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFFFDDAA),
                    Color(0xFFB8753C),
                    Color(0xFF61351F),
                    Color(0xFF9D582E),
                    Color(0xFFFFD18D),
                  ],
                  stops: <double>[0, .20, .52, .78, 1],
                ),
                border: Border.all(
                  color: const Color(0xFF59351F),
                  width: 1.6,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 17,
                    offset: Offset(0, 7),
                  ),
                  BoxShadow(
                    color: Color(0x66FFE1AE),
                    blurRadius: 2,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(frame),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(frame * .20),
                  child: CustomPaint(
                    size: Size.square(innerSide),
                    painter: _PrototypeBoardPainter(players: players),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrototypeBoardPainter extends CustomPainter {
  final List<LudoPlayer> players;
  final LudoBoardGeometry geometry = LudoBoardGeometry.instance;

  _PrototypeBoardPainter({required this.players});

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final cell = side / LudoBoardGeometry.gridSize;
    final boardRect = Rect.fromLTWH(0, 0, side, side);

    canvas.drawRect(boardRect, Paint()..color = const Color(0xFFFFFCF5));

    // Base tiles. Home quadrants are deliberately solid, like the reference;
    // route and safe cells remain white so every colored lane is easy to read.
    for (final boardCell in geometry.cells) {
      final rect = geometry.cellRect(boardCell.position, side);
      final tone = boardCell.ownerColor == null
          ? null
          : prototypeColorFor(boardCell.ownerColor!);

      switch (boardCell.kind) {
        case LudoBoardCellKind.home:
          canvas.drawRect(rect, Paint()..color = tone!);
          break;
        case LudoBoardCellKind.mainPath:
          canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFEFA));
          break;
        case LudoBoardCellKind.safe:
          canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFDF7));
          _paintStar(canvas, rect.center, cell * .19);
          break;
        case LudoBoardCellKind.start:
          canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFEFA));
          _paintStartMark(canvas, rect, tone!, cell);
          break;
        case LudoBoardCellKind.homeLane:
          _paintHomeLaneTile(canvas, rect, tone!, cell);
          break;
        case LudoBoardCellKind.finish:
          canvas.drawRect(rect, Paint()..color = tone!);
          break;
        case LudoBoardCellKind.center:
          canvas.drawRect(rect, Paint()..color = const Color(0xFFFFF8E9));
          break;
      }
    }

    // Enlarged recessed circles fully contain the four token locations in
    // each home quadrant. Home interiors have no grid overlay.
    _paintHomeBases(canvas, side, cell);

    // The central square is fully covered by four triangles; no grid is drawn
    // over it. Each triangle base faces the corresponding Home Lane.
    _paintCenter(canvas, cell);

    // Keep cell separators on the playable tracks, like the reference image,
    // while skipping home interiors and the central triangle square.
    _paintGrid(canvas, side, cell);

    // Strong square borders make all four homes unmistakable.
    _paintHomeFrames(canvas, side, cell);

    // Tokens are rendered on top of every cell so they remain crisp and tactile.
    _paintTokens(canvas, side, cell);

    // The lock is purely visual and sits on the first Home Lane cell.
    _paintHomeLaneLocks(canvas, side, cell);

    canvas.drawRect(
      boardRect.deflate(.65),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, cell * .075).toDouble()
        ..color = const Color(0xFF4C2A1A),
    );
  }

  void _paintHomeBases(Canvas canvas, double side, double cell) {
    for (final color in LudoPlayerColor.values) {
      final homeRect = geometry.homeZoneRect(color, side);
      final tone = prototypeColorFor(color);
      final center = homeRect.center;
      final radius = cell * 2.82;
      final bowlRect = Rect.fromCircle(center: center, radius: radius);
      final darkTone = Color.lerp(tone, Colors.black, .23)!;
      final lightTone = Color.lerp(tone, Colors.white, .18)!;

      canvas.drawCircle(
        center + Offset(0, cell * .09),
        radius * 1.03,
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * .14),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.22, -.25),
            radius: 1.15,
            colors: <Color>[lightTone, tone, darkTone],
            stops: const <double>[0, .63, 1],
          ).createShader(bowlRect),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, cell * .07).toDouble()
          ..color = darkTone.withValues(alpha: .72),
      );
      canvas.drawCircle(
        center - Offset(0, cell * .035),
        radius * .965,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.65, cell * .035).toDouble()
          ..color = Colors.white.withValues(alpha: .38),
      );

      // The dimples represent empty token pads. Actual tokens cover their own
      // dimples when _paintTokens runs later.
      for (var tokenIndex = 0; tokenIndex < 4; tokenIndex++) {
        final pad = geometry.tokenHomePosition(
          color: color,
          tokenIndex: tokenIndex,
        );
        final padCenter = geometry.cellCenter(pad, side);
        final padRadius = cell * .49;

        canvas.drawCircle(
          padCenter + Offset(0, cell * .025),
          padRadius,
          Paint()..color = darkTone.withValues(alpha: .32),
        );
        canvas.drawCircle(
          padCenter,
          padRadius * .82,
          Paint()..color = darkTone.withValues(alpha: .25),
        );
        canvas.drawCircle(
          padCenter - Offset(padRadius * .20, padRadius * .24),
          padRadius * .20,
          Paint()..color = Colors.white.withValues(alpha: .08),
        );
      }
    }
  }

  void _paintGrid(Canvas canvas, double side, double cell) {
    final paint = Paint()
      ..color = const Color(0xFF28333A).withValues(alpha: .82)
      ..strokeWidth = math.max(.55, cell * .045).toDouble()
      ..style = PaintingStyle.stroke;

    // Draw each non-home tile outline. This creates the grid in the paths while
    // leaving the four colored home interiors smooth and free of gridlines.
    for (final boardCell in geometry.cells) {
      final position = boardCell.position;
      final insideCenterSquare = position.row >= 7 &&
          position.row <= 9 &&
          position.column >= 7 &&
          position.column <= 9;
      if (boardCell.kind == LudoBoardCellKind.home || insideCenterSquare) {
        continue;
      }
      canvas.drawRect(geometry.cellRect(position, side), paint);
    }
  }

  void _paintHomeFrames(Canvas canvas, double side, double cell) {
    for (final color in LudoPlayerColor.values) {
      final home = geometry.homeZoneRect(color, side);
      final tone = prototypeColorFor(color);
      final darkTone = Color.lerp(tone, Colors.black, .32)!;

      canvas.drawShadow(
        Path()..addRect(home),
        darkTone.withValues(alpha: .58),
        cell * .22,
        true,
      );
      canvas.drawRect(
        home,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.2, cell * .12).toDouble()
          ..color = darkTone,
      );
      canvas.drawRect(
        home.deflate(cell * .075),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, cell * .035).toDouble()
          ..color = Colors.white.withValues(alpha: .48),
      );
    }
  }

  void _paintStartMark(Canvas canvas, Rect rect, Color tone, double cell) {
    final center = rect.center;
    final badgeRadius = cell * .31;
    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()..color = tone.withValues(alpha: .12),
    );
    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, cell * .055).toDouble()
        ..color = tone,
    );
    canvas.drawCircle(center, cell * .08, Paint()..color = tone);
    _paintStar(canvas, center, cell * .15);
  }

  void _paintHomeLaneTile(Canvas canvas, Rect rect, Color tone, double cell) {
    canvas.drawRect(rect, Paint()..color = tone);
    canvas.drawRect(
      rect.deflate(cell * .045),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, cell * .035).toDouble()
        ..color = Color.lerp(tone, Colors.black, .20)!,
    );
    canvas.drawLine(
      rect.topLeft + Offset(cell * .08, cell * .08),
      rect.topRight + Offset(-cell * .08, cell * .08),
      Paint()
        ..color = Colors.white.withValues(alpha: .25)
        ..strokeWidth = math.max(.6, cell * .025).toDouble(),
    );
  }

  void _paintCenter(Canvas canvas, double cell) {
    final start = 6 * cell;
    final end = 9 * cell;
    final rect = Rect.fromLTRB(start, start, end, end);
    final center = rect.center;
    // Rotate the old diamond-like wedge arrangement by 45 degrees so each
    // triangle base faces its matching Home Lane. The four apexes meet at the
    // exact center and the four triangles cover the full central square.
    final topLeft = rect.topLeft;
    final topRight = rect.topRight;
    final bottomRight = rect.bottomRight;
    final bottomLeft = rect.bottomLeft;

    final slices = <_TriangleSlice>[
      // Green enters from the left Home Lane.
      _TriangleSlice(
        prototypeColorFor(LudoPlayerColor.green),
        topLeft,
        bottomLeft,
        center,
      ),
      // Yellow enters from the top Home Lane.
      _TriangleSlice(
        prototypeColorFor(LudoPlayerColor.yellow),
        topLeft,
        topRight,
        center,
      ),
      // Blue enters from the right Home Lane.
      _TriangleSlice(
        prototypeColorFor(LudoPlayerColor.blue),
        topRight,
        bottomRight,
        center,
      ),
      // Red enters from the bottom Home Lane.
      _TriangleSlice(
        prototypeColorFor(LudoPlayerColor.red),
        bottomLeft,
        bottomRight,
        center,
      ),
    ];

    for (final slice in slices) {
      final path = Path()
        ..moveTo(slice.center.dx, slice.center.dy)
        ..lineTo(slice.a.dx, slice.a.dy)
        ..lineTo(slice.b.dx, slice.b.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = slice.color);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, cell * .035).toDouble()
          ..color = const Color(0xFF263239).withValues(alpha: .62),
      );
    }

    canvas.drawCircle(
      center,
      cell * .24,
      Paint()..color = const Color(0xFFFFF8E8),
    );
    canvas.drawCircle(
      center,
      cell * .24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.9, cell * .05).toDouble()
        ..color = const Color(0xFF75442C),
    );
    canvas.drawCircle(center, cell * .115, Paint()..color = const Color(0xFF453026));

    // Keep the center as one square; do not draw the normal 15x15 grid over
    // the four diagonal color wedges.
    canvas.drawRect(
      rect.deflate(.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, cell * .055).toDouble()
        ..color = const Color(0xFF28333A),
    );
  }

  void _paintTokens(Canvas canvas, double side, double cell) {
    final groups = <Position, List<_TokenVisual>>{};
    for (final player in players) {
      for (final token in player.tokens) {
        final position = token.isInitial
            ? geometry.tokenHomePosition(
                color: player.color,
                tokenIndex: token.tokenIndex,
              )
            : token.position;
        groups.putIfAbsent(position, () => <_TokenVisual>[]).add(
              _TokenVisual(color: player.color, position: position),
            );
      }
    }

    final radius = cell * .355;
    for (final group in groups.values) {
      for (var i = 0; i < group.length; i++) {
        final item = group[i];
        final center = geometry.cellCenter(item.position, side) +
            _stackOffset(i, group.length, cell);
        final tone = prototypeColorFor(item.color);
        final darkTone = Color.lerp(tone, Colors.black, .30)!;
        final lightTone = Color.lerp(tone, Colors.white, .45)!;
        final tokenRect = Rect.fromCircle(center: center, radius: radius);

        // Drop shadow, outer metal-like rim, colored coin and inner ring.
        canvas.drawCircle(
          center + Offset(0, cell * .055),
          radius * 1.14,
          Paint()
            ..color = const Color(0x99000000)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * .08),
        );
        canvas.drawCircle(center, radius * 1.12, Paint()..color = const Color(0xFFFFF4D8));
        canvas.drawCircle(
          center,
          radius * 1.04,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, cell * .055).toDouble()
            ..color = darkTone,
        );
        canvas.drawCircle(
          center,
          radius * .96,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.38, -.48),
              radius: 1.2,
              colors: <Color>[lightTone, tone, darkTone],
              stops: const <double>[0, .55, 1],
            ).createShader(tokenRect),
        );
        canvas.drawCircle(
          center,
          radius * .72,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.8, cell * .035).toDouble()
            ..color = Colors.white.withValues(alpha: .88),
        );
        _paintTokenEmblem(canvas, center, radius);
        canvas.drawCircle(
          center - Offset(radius * .29, radius * .34),
          radius * .15,
          Paint()..color = Colors.white.withValues(alpha: .60),
        );
      }
    }
  }

  void _paintTokenEmblem(Canvas canvas, Offset center, double radius) {
    final emblemPaint = Paint()..color = const Color(0xFFFFF9EB).withValues(alpha: .96);
    // A compact pawn-like emblem remains legible even on a small mobile cell.
    canvas.drawCircle(
      center - Offset(0, radius * .23),
      radius * .16,
      emblemPaint,
    );
    final bodyRect = Rect.fromCenter(
      center: center + Offset(0, radius * .19),
      width: radius * .58,
      height: radius * .40,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(radius * .16)),
      emblemPaint,
    );
    canvas.drawCircle(
      center + Offset(0, radius * .02),
      radius * .055,
      Paint()..color = const Color(0xFF6C4B31).withValues(alpha: .75),
    );
  }

  Offset _stackOffset(int index, int count, double cell) {
    const two = <Offset>[Offset(-.16, -.16), Offset(.16, .16)];
    const three = <Offset>[
      Offset(-.15, -.13),
      Offset(.15, -.13),
      Offset(0, .16),
    ];
    const four = <Offset>[
      Offset(-.16, -.16),
      Offset(.16, -.16),
      Offset(-.16, .16),
      Offset(.16, .16),
    ];

    if (count <= 1) return Offset.zero;
    final offsets = count == 2 ? two : count == 3 ? three : four;
    final safeIndex = index.clamp(0, offsets.length - 1).toInt();
    return offsets[safeIndex] * cell;
  }

  void _paintHomeLaneLocks(Canvas canvas, double side, double cell) {
    // Always show the lock marker on all four home-lane entry cells, even in a
    // 2- or 3-player match. Missing players default to locked in this preview.
    for (final color in LudoPlayerColor.values) {
      LudoPlayer? owner;
      for (final candidate in players) {
        if (candidate.color == color) {
          owner = candidate;
          break;
        }
      }
      // Once this player has captured at least once, remove the marker
      // completely. The Home Lane remains visually open without an icon.
      if (owner?.hasCaptured ?? false) continue;

      final entry = _pathFor(color).homePath.first;
      final center = geometry.cellCenter(entry, side);
      final tone = prototypeColorFor(color);
      final darkTone = Color.lerp(tone, Colors.black, .44)!;
      final radius = cell * .31;

      // Contrast badge keeps the lock visible on the solid colored first lane.
      canvas.drawCircle(
        center,
        radius * 1.14,
        Paint()..color = const Color(0xFFFFF8E8),
      );
      canvas.drawCircle(center, radius, Paint()..color = darkTone);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, cell * .035).toDouble()
          ..color = Colors.white.withValues(alpha: .82),
      );

      final w = cell * .24;
      final bodyRect = Rect.fromCenter(
        center: center + Offset(0, cell * .07),
        width: w,
        height: cell * .19,
      );
      final iconPaint = Paint()
        ..color = const Color(0xFFFFF9EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.15, cell * .055).toDouble()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final shackle = Path()
        ..moveTo(center.dx - w * .30, center.dy + cell * .015)
        ..lineTo(center.dx - w * .30, center.dy - cell * .075)
        ..cubicTo(
          center.dx - w * .30,
          center.dy - cell * .22,
          center.dx + w * .30,
          center.dy - cell * .22,
          center.dx + w * .30,
          center.dy - cell * .075,
        );
      // This badge is drawn only while the lane is locked, so always draw
      // the closed shackle here. After the first capture, the loop continues
      // above and no badge is painted for this player. 
      shackle.lineTo(center.dx + w * .30, center.dy + cell * .015);
      canvas.drawPath(shackle, iconPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(cell * .035)),
        Paint()..color = const Color(0xFFFFF9EC),
      );
      canvas.drawCircle(
        center + Offset(0, cell * .055),
        cell * .022,
        Paint()..color = darkTone,
      );
    }
  }

  void _paintStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    const points = 5;
    final inner = radius * .42;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF68736F));
  }

  LudoPath _pathFor(LudoPlayerColor color) {
    switch (color) {
      case LudoPlayerColor.green:
        return LudoPaths.green;
      case LudoPlayerColor.yellow:
        return LudoPaths.yellow;
      case LudoPlayerColor.red:
        return LudoPaths.red;
      case LudoPlayerColor.blue:
        return LudoPaths.blue;
    }
  }

  @override
  bool shouldRepaint(covariant _PrototypeBoardPainter oldDelegate) {
    return oldDelegate.players != players;
  }
}

class _TokenVisual {
  final LudoPlayerColor color;
  final Position position;

  const _TokenVisual({required this.color, required this.position});
}

class _TriangleSlice {
  final Color color;
  final Offset a;
  final Offset b;
  final Offset center;

  const _TriangleSlice(this.color, this.a, this.b, this.center);
}
