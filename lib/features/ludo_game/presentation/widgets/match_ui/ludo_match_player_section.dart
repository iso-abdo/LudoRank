import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_die_face.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/match_ui_colors.dart';

/// Current player: active card with dice actions. Other players: name only.
class LudoMatchPlayerSection extends StatelessWidget {
  final LudoPlayer player;
  final bool isCurrent;
  final TurnState? turnState;
  final AvailableRolls availableRolls;
  final bool canRoll;
  final VoidCallback onRoll;
  final double height;

  const LudoMatchPlayerSection({
    super.key,
    required this.player,
    required this.isCurrent,
    required this.turnState,
    required this.availableRolls,
    required this.canRoll,
    required this.onRoll,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = matchUiColorFor(player.color);
    if (!isCurrent) {
      return Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF211B2A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: .40), width: 1),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
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
      );
    }

    final foreground = player.color == LudoPlayerColor.yellow
        ? const Color(0xFF21182B)
        : Colors.white;
    final lastRoll = turnState?.lastRoll;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: .34),
            color.withValues(alpha: .18),
            const Color(0xFF201A29),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2.1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: .25),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
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
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'دورك',
                  style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              MatchDieFace(value: lastRoll, size: 32),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: canRoll ? onRoll : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      disabledBackgroundColor: color.withValues(alpha: .35),
                      foregroundColor: foreground,
                      disabledForegroundColor: foreground.withValues(alpha: .72),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.casino_rounded, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        canRoll ? 'رمي النرد' : (turnState?.isPlaying == true ? 'اختر حجرًا' : 'انتظر دورك'),
                        maxLines: 1,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            child: availableRolls.isNotEmpty
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableRolls.rolls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 5),
                    itemBuilder: (context, index) {
                      final roll = availableRolls.rolls[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181321),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: color.withValues(alpha: .72)),
                        ),
                        child: MatchDieFace(
                          value: roll.value,
                          size: 18,
                        ),
                      );
                    },
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      turnState?.isRolling == true ? 'اضغط لرمي النرد' : 'لا توجد رميات متبقية',
                      style: const TextStyle(color: Colors.white60, fontSize: 9),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
