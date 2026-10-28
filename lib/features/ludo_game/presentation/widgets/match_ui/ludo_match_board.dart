import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/presentation/geometry/ludo_board_geometry.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/ludo_match_board_art.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_die_face.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_ui_colors.dart';
import 'package:ludo_rank/features/ludo_game/domain/constants/ludo_paths.dart';

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Live interactive wrapper around the visual board.
///
/// The board handles presentation and input only.
/// Legal moves and move execution remain controlled by the game logic.
class LudoMatchBoard extends StatefulWidget {
  final List<LudoPlayer> players;
  final String? currentPlayerId;
  final List<MoveOption> availableMoves;
  final String? selectedTokenId;
  final int? selectedRollSequence;
  final MoveOption? pendingAutoMove;
  final ValueChanged<LudoToken> onTokenTap;

  /// Legal destinations for the currently selected token.
  final Map<Position, List<MoveOption>> legalMoveDestinations;

  /// Returns the dice value associated with a move.
  final int? Function(MoveOption) rollValueForMove;

  /// Called when a specific legal move is selected.
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
    this.selectedRollSequence,
    this.pendingAutoMove,
  });

  @override
  State<LudoMatchBoard> createState() => _LudoMatchBoardState();
}

class _LudoMatchBoardState extends State<LudoMatchBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  MoveOption? _animatingMove;
  List<Position> _animationPath = <Position>[];
  String? _animatingTokenId;
  bool _startingAutoMove = false;

  late final AudioPlayer _stepPlayer;
  int _lastSoundStep = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addStatusListener(_onAnimationStatus);

    _stepPlayer = AudioPlayer();
    _stepPlayer.setReleaseMode(ReleaseMode.stop);

    _controller.addListener(_onAnimationTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryStartAutomaticMove();
    });
  }

  @override
  void didUpdateWidget(covariant LudoMatchBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pendingAutoMove == null) {
      _startingAutoMove = false;
    }

    if (widget.pendingAutoMove != oldWidget.pendingAutoMove ||
        widget.selectedTokenId != oldWidget.selectedTokenId ||
        widget.selectedRollSequence != oldWidget.selectedRollSequence ||
        widget.availableMoves != oldWidget.availableMoves) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryStartAutomaticMove();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);

        if (!side.isFinite || side <= 0) {
          return const SizedBox.shrink();
        }

        final frame = (side * .031).clamp(7.0, 11.0).toDouble();
        final innerSide = side - frame * 2;

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: LudoMatchBoardArt(
                    players: widget.players,
                    hiddenTokenId: _animatingTokenId,
                  ),
                ),

                IgnorePointer(
                  ignoring: _animatingMove != null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      ..._buildTokenTargets(frame: frame, innerSide: innerSide),
                      ..._buildDestinationTargets(
                        frame: frame,
                        innerSide: innerSide,
                      ),
                    ],
                  ),
                ),

                if (_animatingMove != null)
                  _buildAnimatedToken(frame: frame, innerSide: innerSide),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_stepPlayer.dispose());
    super.dispose();
  }

  void _tryStartAutomaticMove() {
    if (_animatingMove != null || !mounted) return;

    // الحركة الوحيدة التي اكتشفها الـ Provider بعد رمي النرد.
    final pending = widget.pendingAutoMove;

    if (pending != null && !_startingAutoMove) {
      _startingAutoMove = true;
      _startMoveAnimation(pending);
      return;
    }

    // لو اختار اللاعب قطعة ورمية نرد، وكانت هناك حركة قانونية واحدة
    // تطابق الاختيار، شغّل الأنيميشن بدل التنفيذ المباشر.
    final tokenId = widget.selectedTokenId;
    if (tokenId == null) return;

    final candidates = widget.availableMoves
        .where((move) {
          final moveTokenId = switch (move) {
            MoveToken(:final tokenId) => tokenId,
            ExitToken(:final tokenId) => tokenId,
          };

          return moveTokenId == tokenId &&
              (widget.selectedRollSequence == null ||
                  move.rollSequence == widget.selectedRollSequence);
        })
        .toList(growable: false);

    if (candidates.length == 1) {
      _startMoveAnimation(candidates.single);
    }
  }

  bool _sameMove(MoveOption a, MoveOption b) {
    if (a is MoveToken && b is MoveToken) {
      return a.tokenId == b.tokenId &&
          a.steps == b.steps &&
          a.rollSequence == b.rollSequence;
    }

    if (a is ExitToken && b is ExitToken) {
      return a.tokenId == b.tokenId && a.rollSequence == b.rollSequence;
    }

    return false;
  }

  void _startMoveAnimation(MoveOption move) {
    if (_animatingMove != null) return;

    // لا نحرّك أي قطعة بناءً على اختيار قديم لم يعد قانونيًا.
    if (!widget.availableMoves.any((candidate) => _sameMove(candidate, move))) {
      return;
    }

    final tokenId = switch (move) {
      MoveToken(:final tokenId) => tokenId,
      ExitToken(:final tokenId) => tokenId,
    };

    final player = widget.players.cast<LudoPlayer?>().firstWhere(
      (p) => p?.tokens.any((token) => token.id == tokenId) ?? false,
      orElse: () => null,
    );

    if (player == null) return;

    final token = player.tokens.firstWhere((t) => t.id == tokenId);
    final path = _pathFor(player.color);
    final positions = <Position>[token.position];

    if (move is ExitToken) {
      // الخروج من قاعدة اللاعب إلى نقطة البداية.
      positions.add(path.startingPosition);
    } else if (move is MoveToken) {
      var step = token.positionInPath;
      var homeEntryPending = token.homeEntryPending;
      var destinationUsesHomeLane = false;

      for (var i = 0; i < move.steps; i++) {
        if (step == LudoPath.finishStep) return;

        // نفس تفسير المحرك للخطوة 51 والحارة المنزلية.
        final useHomeLane =
            player.hasCaptured &&
            !(homeEntryPending && step == LudoPath.lastMainLoopStep);

        final nextStep = path.nextStep(
          currentStep: step,
          useHomeLane: useHomeLane,
        );

        destinationUsesHomeLane =
            useHomeLane && nextStep >= LudoPath.homeLaneStartStep;

        if (destinationUsesHomeLane && nextStep == LudoPath.homeLaneStartStep) {
          homeEntryPending = false;
        }

        step = nextStep;

        positions.add(
          path.positionAt(step: step, useHomeLane: destinationUsesHomeLane),
        );
      }
    }

    if (positions.length < 2) return;

    setState(() {
      _lastSoundStep = 0;
      _animatingMove = move;
      _animatingTokenId = tokenId;
      _animationPath = positions;
    });

    // تحديد مدة الحركة قبل تشغيل الأنيميشن.
    _controller.duration = Duration(
      milliseconds: math.max(220, (positions.length - 1) * 180),
    );

    // تشغيل الحركة من البداية.
    _controller.forward(from: 0);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    final move = _animatingMove;
    if (move == null) return;

    // بعد اكتمال الأنيميشن فقط، اطلب من الـ Provider تنفيذ الحركة
    // عن طريق LudoGameEngine.
    widget.onMoveTap(move);

    setState(() {
      _animatingMove = null;
      _animatingTokenId = null;
      _animationPath = <Position>[];
    });

    _controller.reset();
  }

  void _onAnimationTick() {
    if (_animatingMove == null || _animationPath.length < 2) {
      return;
    }

    final totalSteps = _animationPath.length - 1;
    final currentStep = (_controller.value * totalSteps).floor().clamp(
      0,
      totalSteps,
    );

    if (currentStep <= _lastSoundStep) return;

    _lastSoundStep = currentStep;

    unawaited(_playStepSound());
  }

  Future<void> _playStepSound() async {
    try {
      await _stepPlayer.stop();
      await _stepPlayer.play(AssetSource('audio/ludorank_token_step.mp3'));
    } catch (error) {
      debugPrint('Token movement sound failed: $error');
    }
  }

  LudoPath _pathFor(LudoPlayerColor color) {
    return switch (color) {
      LudoPlayerColor.red => LudoPaths.red,
      LudoPlayerColor.green => LudoPaths.green,
      LudoPlayerColor.yellow => LudoPaths.yellow,
      LudoPlayerColor.blue => LudoPaths.blue,
    };
  }

  Offset _animatedCenter(double innerSide) {
    final count = _animationPath.length;
    final geometry = LudoBoardGeometry.instance;
    final scaled = _controller.value * (count - 1);
    final index = scaled.floor().clamp(0, count - 2);
    final fraction = (scaled - index).clamp(0.0, 1.0);

    final from = geometry.cellCenter(_animationPath[index], innerSide);
    final to = geometry.cellCenter(_animationPath[index + 1], innerSide);

    return Offset.lerp(from, to, fraction)!;
  }

  List<Widget> _buildTokenTargets({
    required double frame,
    required double innerSide,
  }) {
    final geometry = LudoBoardGeometry.instance;
    final cell = innerSide / LudoBoardGeometry.gridSize;
    final diameter = cell * 1.15;
    final widgets = <Widget>[];

    for (final player in widget.players) {
      for (final token in player.tokens) {
        // لا نسمح باختيار قطعة لاعب آخر.
        if (player.playerId != widget.currentPlayerId) continue;

        // القطع التي ليس لها حركة قانونية لا تحتاج منطقة ضغط.
        final hasLegalMove = widget.availableMoves.any((move) {
          return switch (move) {
            MoveToken(:final tokenId) => tokenId == token.id,
            ExitToken(:final tokenId) => tokenId == token.id,
          };
        });

        if (!hasLegalMove) continue;

        final position = token.isInitial
            ? geometry.tokenHomePosition(
                color: player.color,
                tokenIndex: token.tokenIndex,
              )
            : token.position;

        final center = geometry.cellCenter(position, innerSide);
        final isSelected = widget.selectedTokenId == token.id;

        widgets.add(
          Positioned(
            left: frame + center.dx - diameter / 2,
            top: frame + center.dy - diameter / 2,
            width: diameter,
            height: diameter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onTokenTap(token),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildDestinationTargets({
    required double frame,
    required double innerSide,
  }) {
    final selectedTokenId = widget.selectedTokenId;

    if (selectedTokenId == null || _animatingMove != null) {
      return const <Widget>[];
    }

    final geometry = LudoBoardGeometry.instance;
    final cell = innerSide / LudoBoardGeometry.gridSize;
    final size = cell * .76;
    final widgets = <Widget>[];

    for (final entry in widget.legalMoveDestinations.entries) {
      final candidates = entry.value
          .where((move) {
            final matchesToken = switch (move) {
              MoveToken(:final tokenId) => tokenId == selectedTokenId,
              ExitToken(:final tokenId) => tokenId == selectedTokenId,
            };

            return matchesToken &&
                (widget.selectedRollSequence == null ||
                    move.rollSequence == widget.selectedRollSequence);
          })
          .toList(growable: false);

      if (candidates.isEmpty) continue;

      final center = geometry.cellCenter(entry.key, innerSide);
      final diceValue = widget.rollValueForMove(candidates.first);

      widgets.add(
        Positioned(
          left: frame + center.dx - size / 2,
          top: frame + center.dy - size / 2,
          width: size,
          height: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_animatingMove != null) return;

              // لا نخمن الحركة إذا بقي أكثر من اختيار صالح.
              if (candidates.length != 1) return;

              _startMoveAnimation(candidates.single);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xDDFFFFFF),
                borderRadius: BorderRadius.circular(size * .22),
                border: Border.all(color: const Color(0xFFFFD166), width: 2),
              ),
              child: Center(
                child: MatchDieFace(value: diceValue, size: size * .85),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildAnimatedToken({
    required double frame,
    required double innerSide,
  }) {
    if (_animatingMove == null || _animationPath.length < 2) {
      return const SizedBox.shrink();
    }

    final tokenId = _animatingTokenId;
    LudoPlayer? owner;

    for (final player in widget.players) {
      if (player.tokens.any((token) => token.id == tokenId)) {
        owner = player;
        break;
      }
    }

    if (owner == null) return const SizedBox.shrink();

    final tone = matchUiColorFor(owner.color);
    final cell = innerSide / LudoBoardGeometry.gridSize;
    final diameter = cell * .71;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final center = _animatedCenter(innerSide);

        return Positioned(
          left: frame + center.dx - diameter / 2,
          top: frame + center.dy - diameter / 2,
          width: diameter,
          height: diameter,
          child: child!,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.35, -.4),
            colors: <Color>[
              Color.lerp(tone, Colors.white, .45)!,
              tone,
              Color.lerp(tone, Colors.black, .30)!,
            ],
          ),
          border: Border.all(color: const Color(0xFFFFF4D8), width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Color(0xFFFFF9EB), size: 20),
      ),
    );
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
