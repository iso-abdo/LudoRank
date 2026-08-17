import 'package:equatable/equatable.dart';

class DiceRoll extends Equatable {
  final int value;

  /// ترتيب الرمية داخل الدور الحالي.
  ///
  /// 1 = أول رمية
  /// 2 = ثاني رمية
  /// 3 = ثالث رمية
  final int sequence;

  const DiceRoll({
    required this.value,
    required this.sequence,
  })  : assert(value >= 1 && value <= 6),
        assert(sequence >= 1);

  bool get isSix => value == 6;

  @override
  List<Object?> get props => [
    value,
    sequence,
  ];
}