import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/prototype/prototype_die_face.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/prototype/prototype_ludo_colors.dart';

class PrototypePlayerSection extends StatelessWidget {
  final LudoPlayer player;
  final bool isCurrent;
  final int? lastRoll;
  final List<int> availableRolls;
  final VoidCallback onRoll;
  final ValueChanged<int> onUseRoll;

  const PrototypePlayerSection({
    super.key,
    required this.player,
    required this.isCurrent,
    required this.lastRoll,
    required this.availableRolls,
    required this.onRoll,
    required this.onUseRoll,
  });

  @override
  Widget build(BuildContext context) {
    final color = prototypeColorFor(player.color);
    final foreground = player.color == LudoPlayerColor.yellow
        ? const Color(0xFF21182B)
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: isCurrent ? 8 : 10,
        vertical: isCurrent ? 7 : 4,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? null : const Color(0xFF211B2A),
        gradient: isCurrent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  color.withValues(alpha: .34),
                  color.withValues(alpha: .18),
                  const Color(0xFF201A29),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrent
              ? color
              : color.withValues(alpha: 0.42),
          width: isCurrent ? 2.1 : 1.05,
        ),
        boxShadow: isCurrent
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.27),
                  blurRadius: 15,
                  spreadRadius: .4,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: .045),
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                ),
              ]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: isCurrent
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'دورك',
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    PrototypeDieFace(value: lastRoll, size: 34),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: onRoll,
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: foreground,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.casino_rounded, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'رمي النرد',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (availableRolls.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 25,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableRolls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemBuilder: (context, index) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onUseRoll(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181321),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                PrototypeDieFace(
                                  value: availableRolls[index],
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.close_rounded,
                                  size: 11,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            )
          : Center(
              // Agreement: non-current players show their name only.
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
