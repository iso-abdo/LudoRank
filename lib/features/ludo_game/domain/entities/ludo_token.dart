
import 'position.dart';

enum LudoTokenColor {
  green,
  yellow,
  blue,
  red,
}

enum LudoTokenState {
  initial,
  home,
  normal,
  safe,
  safeInPair,
  finished,
}

class LudoToken {
  final String id;
  final int tokenIndex;
  final Position position;
  final bool finished;

  const LudoToken({
    required this.id,
    required this.tokenIndex,
    required this.position,
    this.finished = false,
  });

  LudoToken copyWith({
    String? id,
    int? tokenIndex,
    Position? position,
    bool? finished,
  }) {
    return LudoToken(
      id: id ?? this.id,
      tokenIndex: tokenIndex ?? this.tokenIndex,
      position: position ?? this.position,
      finished: finished ?? this.finished,
    );
  }
}