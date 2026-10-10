import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/presentation/geometry/ludo_board_geometry.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/prototype/ludo_prototype_board_frame.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/prototype/prototype_controls.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/prototype/prototype_player_section.dart';

class LudoMatchPrototypePage extends StatefulWidget {
  const LudoMatchPrototypePage({super.key});

  @override
  State<LudoMatchPrototypePage> createState() => _LudoMatchPrototypePageState();
}

class _LudoMatchPrototypePageState extends State<LudoMatchPrototypePage> {
  final Random _random = Random();
  int _playerCount = 4;
  int _currentPlayerIndex = 0;
  int? _lastRoll;
  final List<int> _availableRolls = <int>[];

  static const List<_DemoPlayerSpec> _specs = <_DemoPlayerSpec>[
    _DemoPlayerSpec(
      id: 'prototype-green',
      name: 'إمام',
      color: LudoPlayerColor.green,
      seat: 0,
      hasCaptured: false,
    ),
    _DemoPlayerSpec(
      id: 'prototype-yellow',
      name: 'عبدالله',
      color: LudoPlayerColor.yellow,
      seat: 1,
      hasCaptured: true,
    ),
    _DemoPlayerSpec(
      id: 'prototype-red',
      name: 'حسن',
      color: LudoPlayerColor.red,
      seat: 2,
      hasCaptured: false,
    ),
    _DemoPlayerSpec(
      id: 'prototype-blue',
      name: 'يوسف',
      color: LudoPlayerColor.blue,
      seat: 3,
      hasCaptured: true,
    ),
  ];

  List<LudoPlayer> get _players => _specs
      .take(_playerCount)
      .map(_makeDemoPlayer)
      .toList(growable: false);

  LudoPlayer _makeDemoPlayer(_DemoPlayerSpec spec) {
    final path = _pathFor(spec.color);
    final demoStep = (4 + spec.seat * 9) % path.mainLoopPath.length;
    final tokens = List<LudoToken>.generate(4, (tokenIndex) {
      final isOnBoard = tokenIndex == 0;
      final position = isOnBoard
          ? path.mainLoopPath[demoStep]
          : LudoBoardGeometry.instance.tokenHomePosition(
              color: spec.color,
              tokenIndex: tokenIndex,
            );

      return LudoToken(
        id: '${spec.id}-token-$tokenIndex',
        playerId: spec.id,
        tokenIndex: tokenIndex,
        position: position,
        positionInPath: isOnBoard ? demoStep : -1,
        state: isOnBoard ? LudoTokenState.normal : LudoTokenState.initial,
      );
    }, growable: false);

    return LudoPlayer(
      id: spec.id,
      playerId: spec.id,
      name: spec.name,
      color: spec.color,
      seat: spec.seat,
      tokens: tokens,
      hasCaptured: spec.hasCaptured,
    );
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

  void _rollDice() {
    setState(() {
      _lastRoll = _random.nextInt(6) + 1;
      _availableRolls.add(_lastRoll!);
    });
  }

  void _useRoll(int index) {
    if (index < 0 || index >= _availableRolls.length) return;
    setState(() {
      _availableRolls.removeAt(index);
    });
  }

  void _nextPlayer() {
    setState(() {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerCount;
      _lastRoll = null;
      _availableRolls.clear();
    });
  }

  void _changePlayerCount(int count) {
    setState(() {
      _playerCount = count;
      _currentPlayerIndex %= count;
      _lastRoll = null;
      _availableRolls.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final players = _players;
    final currentPlayer = players[_currentPlayerIndex];
    final playersByColor = <LudoPlayerColor, LudoPlayer>{
      for (final player in players) player.color: player,
    };
    final green = playersByColor[LudoPlayerColor.green];
    final yellow = playersByColor[LudoPlayerColor.yellow];
    final red = playersByColor[LudoPlayerColor.red];
    final blue = playersByColor[LudoPlayerColor.blue];

    final topHasCurrent = _isCurrent(green, currentPlayer) ||
        _isCurrent(yellow, currentPlayer);
    final bottomHasCurrent = _isCurrent(red, currentPlayer) ||
        _isCurrent(blue, currentPlayer);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'رجوع',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'LudoRank',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFF51465E)),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final shortScreen = constraints.maxHeight < 610;
              final activeCardHeight = shortScreen ? 118.0 : 132.0;
              final inactiveCardHeight = shortScreen ? 40.0 : 46.0;
              final rowGap = shortScreen ? 4.0 : 6.0;
              final sidePadding = width < 360 ? 12.0 : 14.0;
              final topHeight = topHasCurrent
                  ? activeCardHeight
                  : ((green != null || yellow != null) ? inactiveCardHeight : 0.0);
              final bottomHeight = bottomHasCurrent
                  ? activeCardHeight
                  : ((red != null || blue != null) ? inactiveCardHeight : 0.0);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(sidePadding, 5, sidePadding, 5),
                    child: Column(
                      children: <Widget>[
                        if (topHeight > 0)
                          SizedBox(
                            height: topHeight,
                            child: _buildHomeSideRow(
                              left: green,
                              right: yellow,
                              currentPlayer: currentPlayer,
                              activeCardHeight: activeCardHeight,
                              inactiveCardHeight: inactiveCardHeight,
                            ),
                          ),
                        SizedBox(height: rowGap),
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, boardConstraints) {
                                final side = min(
                                  boardConstraints.maxWidth,
                                  boardConstraints.maxHeight,
                                );
                                return SizedBox.square(
                                  dimension: side,
                                  child: LudoPrototypeBoardFrame(players: players),
                                );
                              },
                            ),
                          ),
                        ),
                        if (bottomHeight > 0) ...<Widget>[
                          SizedBox(height: rowGap),
                          SizedBox(
                            height: bottomHeight,
                            child: _buildHomeSideRow(
                              left: red,
                              right: blue,
                              currentPlayer: currentPlayer,
                              activeCardHeight: activeCardHeight,
                              inactiveCardHeight: inactiveCardHeight,
                            ),
                          ),
                        ],
                        SizedBox(height: rowGap),
                        PrototypeControls(
                          playerCount: _playerCount,
                          onPlayerCountChanged: _changePlayerCount,
                          onNextPlayer: _nextPlayer,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'معاينة بصرية فقط — من دون تعديل محرك اللعبة أو قواعده.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white54,
                                fontSize: 9,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isCurrent(LudoPlayer? player, LudoPlayer currentPlayer) {
    return player?.playerId == currentPlayer.playerId;
  }

  /// Each card stays beside its matching home quadrant:
  /// green top-left, yellow top-right, red bottom-left, blue bottom-right.
  /// Text content is RTL, but the slot positions are deliberately LTR.
  Widget _buildHomeSideRow({
    required LudoPlayer? left,
    required LudoPlayer? right,
    required LudoPlayer currentPlayer,
    required double activeCardHeight,
    required double inactiveCardHeight,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildPlayerSlot(
              left,
              currentPlayer,
              activeCardHeight,
              inactiveCardHeight,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _buildPlayerSlot(
              right,
              currentPlayer,
              activeCardHeight,
              inactiveCardHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(
    LudoPlayer? player,
    LudoPlayer currentPlayer,
    double activeCardHeight,
    double inactiveCardHeight,
  ) {
    if (player == null) return const SizedBox.shrink();

    final isCurrent = player.playerId == currentPlayer.playerId;
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        height: isCurrent ? activeCardHeight : inactiveCardHeight,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PrototypePlayerSection(
            player: player,
            isCurrent: isCurrent,
            lastRoll: isCurrent ? _lastRoll : null,
            availableRolls: isCurrent ? _availableRolls : const <int>[],
            onRoll: _rollDice,
            onUseRoll: _useRoll,
          ),
        ),
      ),
    );
  }
}

class _DemoPlayerSpec {
  final String id;
  final String name;
  final LudoPlayerColor color;
  final int seat;
  final bool hasCaptured;

  const _DemoPlayerSpec({
    required this.id,
    required this.name,
    required this.color,
    required this.seat,
    required this.hasCaptured,
  });
}

