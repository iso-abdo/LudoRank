import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

/// Compact move chooser that occupies the prototype's bottom control strip.
/// It submits only MoveOption objects already supplied by the engine/provider.
class LudoMatchFooter extends StatelessWidget {
  final String? selectedTokenId;
  final List<MoveOption> availableMoves;
  final TurnState? turnState;
  final ValueChanged<MoveOption> onMove;
  final double height;

  const LudoMatchFooter({
    super.key,
    required this.selectedTokenId,
    required this.availableMoves,
    required this.turnState,
    required this.onMove,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final phase = turnState?.phase;
    if (phase != TurnPhase.playing) {
      final message = switch (phase) {
        TurnPhase.rolling => 'ارمِ النرد لبدء الدور',
        TurnPhase.cancelled => 'تم إلغاء الدور',
        TurnPhase.completed => 'انتهى الدور',
        TurnPhase.playing => '',
        null => 'جاري تجهيز المباراة',
      };
      return _footerShell(
        height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(_phaseIcon(phase), size: 16, color: Colors.white70),
            const SizedBox(width: 7),
            Flexible(
              child: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    if (selectedTokenId == null) {
      final message = availableMoves.isEmpty
          ? 'لا توجد حركة قانونية متاحة'
          : 'اضغط على حجر مضيء لاختيار الحركة';
      return _footerShell(
        height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.touch_app_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 7),
            Flexible(
              child: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    final moves = availableMoves.where((move) => _tokenId(move) == selectedTokenId).toList(growable: false);
    if (moves.isEmpty) {
      return _footerShell(
        height,
        child: const Center(
          child: Text('الحجر المحدد لا يملك حركة قانونية', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return _footerShell(
      height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moves.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final move = moves[index];
          final rollValue = _rollValue(move.rollSequence);
          final title = move is ExitToken ? 'إخراج حجر' : 'تحريك ${(move as MoveToken).steps}';
          final label = rollValue == null ? '#${move.rollSequence}' : '#${move.rollSequence}: $rollValue';
          return SizedBox(
            width: 112,
            child: FilledButton.tonal(
              onPressed: () => onMove(move),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF362B43),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF6B5879))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  Text(label, maxLines: 1, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _footerShell(double height, {required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF241D30),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: child,
    );
  }

  String _tokenId(MoveOption move) {
    if (move is MoveToken) return move.tokenId;
    if (move is ExitToken) return move.tokenId;
    return '';
  }

  int? _rollValue(int sequence) {
    for (final roll in turnState?.rolls ?? const []) {
      if (roll.sequence == sequence) return roll.value;
    }
    return null;
  }

  IconData _phaseIcon(TurnPhase? phase) {
    switch (phase) {
      case TurnPhase.rolling:
        return Icons.casino_outlined;
      case TurnPhase.playing:
        return Icons.touch_app_rounded;
      case TurnPhase.cancelled:
        return Icons.block_rounded;
      case TurnPhase.completed:
        return Icons.check_circle_outline_rounded;
      case null:
        return Icons.hourglass_empty_rounded;
    }
  }
}
