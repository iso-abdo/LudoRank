import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/presentation/geometry/ludo_board_geometry.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/ludo_match_board_art.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_ui_colors.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_die_face.dart';
/// Live interactive wrapper around the v4 visual board art.
///
/// The painter owns only appearance. Token selection is routed back to the
/// existing MatchGameProvider, and legal moves still come from LudoGameEngine.
class LudoMatchBoard extends StatelessWidget {
  final List<LudoPlayer> players;
  final String? currentPlayerId;
  final List<MoveOption> availableMoves;
  final String? selectedTokenId;
  final ValueChanged<LudoToken> onTokenTap;
  final Map<Position, List<MoveOption>> legalMoveDestinations;
  final int? Function(MoveOption) rollValueForMove;
  final ValueChanged<MoveOption> onMoveTap;

  const LudoMatchBoard({
    super.key,
    required this.players,
    required this.currentPlayerId,
    required this.availableMoves,
    required this.selectedTokenId,
    required this.onTokenTap,
    required this.legalMoveDestinations,
    required this.rollValueForMove,
    required this.onMoveTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        if (side <= 0) return const SizedBox.shrink();

        final frame = (side * .031).clamp(7.0, 11.0).toDouble();
        final innerSide = side - frame * 2;

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(child: LudoMatchBoardArt(players: players)),
                ..._buildTokenTargets(
                  frame: frame,
                  innerSide: innerSide,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTokenTargets({
    required double frame,
    required double innerSide,
  }) {
    final groups = <Position, List<_BoardToken>>{};
    final geometry = LudoBoardGeometry.instance;

    for (final player in players) {
      for (final token in player.tokens) {
        final position = token.isInitial
            ? geometry.tokenHomePosition(
                color: player.color,
                tokenIndex: token.tokenIndex,
              )
            : token.position;
        groups.putIfAbsent(position, () => <_BoardToken>[]).add(
              _BoardToken(player: player, token: token, position: position),
            );
      }
    }
    // ============================================================
    //
    // ============================================================
    _buildDestinationTargets(
    destinations: legalMoveDestinations,
    frame: frame,
    innerSide: innerSide,
    ),
    List<Widget> _buildDestinationTargets({
    required Map<Position, List<MoveOption>> destinations,
    required double frame,
    required double innerSide,
    }) {
    final geometry = LudoBoardGeometry.instance;
    final cell = innerSide / LudoBoardGeometry.gridSize;
    final result = <Widget>[];

    for (final entry in destinations.entries) {
    final center = geometry.cellCenter(entry.key, innerSide);
    final moves = entry.value;
    final markerWidth = math.min(cell * 2.8, innerSide * .48);
    final markerHeight = cell * .82;

    result.add(
    Positioned(
    key: ValueKey<String>(
    'destination-${entry.key.row}-${entry.key.column}',
    ),
    left: frame + center.dx - markerWidth / 2,
    top: frame + center.dy - markerHeight / 2,
    width: markerWidth,
    height: markerHeight,
    child: Center(
    child: Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
    color: const Color(0xEE241B30),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
    color: const Color(0xFFFFD66B),
    width: 1.5,
    ),
    boxShadow: const <BoxShadow>[
    BoxShadow(
    color: Color(0x77000000),
    blurRadius: 6,
    ),
    ],
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: moves.map((move) {
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: GestureDetector(
    key: ValueKey<String>(
    'move-${move.runtimeType}-${move.rollSequence}',
    ),
    behavior: HitTestBehavior.opaque,
    onTap: () => onMoveTap(move),
    child: MatchDieFace(
    value: rollValueForMove(move),
    size: cell * .58,
    ),
    ),
    );
    }).toList(growable: false),
    ),
    ),
    ),
    ),
    );
    }

    return result;
    }
    // ============================================================

    final result = <Widget>[];
    final cell = innerSide / LudoBoardGeometry.gridSize;
    final targetSide = cell * .88;

    for (final group in groups.values) {
      for (var index = 0; index < group.length; index++) {
        final item = group[index];
        if (item.player.playerId != currentPlayerId) continue;

        final isMovable = _isTokenMovable(item.token.id);
        final isSelected = item.token.id == selectedTokenId;
        if (!isMovable && !isSelected) continue;

        final center = geometry.cellCenter(item.position, innerSide) +
            _stackOffset(index, group.length, cell);
        final tone = matchUiColorFor(item.player.color);

        result.add(
          Positioned(
            key: ValueKey<String>('tap-${item.token.id}'),
            left: frame + center.dx - targetSide / 2,
            top: frame + center.dy - targetSide / 2,
            width: targetSide,
            height: targetSide,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTokenTap(item.token),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFF4C2)
                        : Colors.white.withValues(alpha: .96),
                    width: isSelected ? 3 : 2.2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (isSelected ? const Color(0xFFFFD66B) : tone)
                          .withValues(alpha: isSelected ? .82 : .65),
                      blurRadius: isSelected ? 11 : 7,
                      spreadRadius: isSelected ? 1.5 : .4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return result;
  }

  bool _isTokenMovable(String tokenId) {
    for (final move in availableMoves) {
      if (move is MoveToken && move.tokenId == tokenId) return true;
      if (move is ExitToken && move.tokenId == tokenId) return true;
    }
    return false;
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
    return offsets[index.clamp(0, offsets.length - 1).toInt()] * cell;
  }
}

class _BoardToken {
  final LudoPlayer player;
  final LudoToken token;
  final Position position;

  const _BoardToken({
    required this.player,
    required this.token,
    required this.position,
  });
}
