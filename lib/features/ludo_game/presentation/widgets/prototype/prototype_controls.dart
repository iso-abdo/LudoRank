import 'package:flutter/material.dart';

class PrototypeControls extends StatelessWidget {
  final int playerCount;
  final ValueChanged<int> onPlayerCountChanged;
  final VoidCallback onNextPlayer;

  const PrototypeControls({
    super.key,
    required this.playerCount,
    required this.onPlayerCountChanged,
    required this.onNextPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 5, 3),
      decoration: BoxDecoration(
        color: const Color(0xFF241D30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'اللاعبون',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 7),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3')),
              ButtonSegment<int>(value: 4, label: Text('4')),
            ],
            selected: <int>{playerCount},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onPlayerCountChanged(selection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              ),
              textStyle: const WidgetStatePropertyAll<TextStyle>(
                TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: onNextPlayer,
            tooltip: 'اللاعب التالي (معاينة)',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.skip_next_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
