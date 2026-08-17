sealed class MoveOption {
  /// رقم تسلسل الرمية التي سيتم استخدامها.
  ///
  /// مثال:
  /// availableRolls = [6(#1), 6(#2), 4(#3)]
  ///
  /// لو الحركة تستخدم الرمية الثانية:
  /// rollSequence = 2
  final int rollSequence;

  const MoveOption({
    required this.rollSequence,
  });
}

/// تحريك Token موجود بالفعل على المسار.
class MoveToken extends MoveOption {
  final String tokenId;

  /// عدد الخطوات التي سيتم تحريك الـ Token بها.
  final int steps;

  const MoveToken({
    required this.tokenId,
    required this.steps,
    required super.rollSequence,
  });
}

/// إخراج Token من الـ Home إلى Starting Cell.
class ExitToken extends MoveOption {
  final String tokenId;

  const ExitToken({
    required this.tokenId,
    required super.rollSequence,
  });
}