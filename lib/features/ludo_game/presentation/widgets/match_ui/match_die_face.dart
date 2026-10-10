import 'package:flutter/material.dart';

class MatchDieFace extends StatelessWidget {
  final int? value;
  final double size;

  const MatchDieFace({
    super.key,
    required this.value,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFF),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFFE2DCEA), width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: value == null
          ? Icon(
              Icons.casino_outlined,
              size: size * 0.55,
              color: const Color(0xFF81788B),
            )
          : CustomPaint(
              painter: _MatchDiePipsPainter(value: value!, size: size),
            ),
    );
  }
}

class _MatchDiePipsPainter extends CustomPainter {
  final int value;
  final double size;

  const _MatchDiePipsPainter({required this.value, required this.size});

  static const Map<int, List<Offset>> _pips = <int, List<Offset>>{
    1: <Offset>[Offset(.5, .5)],
    2: <Offset>[Offset(.28, .28), Offset(.72, .72)],
    3: <Offset>[Offset(.28, .28), Offset(.5, .5), Offset(.72, .72)],
    4: <Offset>[
      Offset(.28, .28), Offset(.72, .28),
      Offset(.28, .72), Offset(.72, .72),
    ],
    5: <Offset>[
      Offset(.28, .28), Offset(.72, .28), Offset(.5, .5),
      Offset(.28, .72), Offset(.72, .72),
    ],
    6: <Offset>[
      Offset(.28, .25), Offset(.72, .25),
      Offset(.28, .5), Offset(.72, .5),
      Offset(.28, .75), Offset(.72, .75),
    ],
  };

  @override
  void paint(Canvas canvas, Size paintSize) {
    final radius = size * 0.075;
    final paint = Paint()
      ..color = const Color(0xFF30213D)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final point in _pips[value] ?? const <Offset>[]) {
      canvas.drawCircle(
        Offset(point.dx * paintSize.width, point.dy * paintSize.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MatchDiePipsPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.size != size;
  }
}
