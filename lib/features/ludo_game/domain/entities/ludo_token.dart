import 'package:equatable/equatable.dart';

import 'position.dart';

enum LudoTokenState { initial, normal, safe, safeInPair, finished }

class LudoToken extends Equatable {
  final String id;

  /// اللاعب صاحب الـ Token
  final String playerId;

  /// رقم الـ Token داخل اللاعب
  /// 0..3
  final int tokenIndex;

  /// مكان الـ Token الحالي على الـ Board

  final Position position;

  /// مكانه المنطقي داخل الـ Path
  ///
  /// -1 = لم يدخل الـ Path
  /// 0..56 = داخل المسار

  final int positionInPath;

  /// حالة الـ Token

  final LudoTokenState state;

  /// هل دخول الـ Home Lane مؤجل لهذا الـ Token؟

  /// يحدث فقط عندما يقوم هذا الـ Token نفسه
  /// بعمل Capture على Main Loop Step 51.
  /// في هذه الحالة:
  /// 51 -> 0 -> 1 -> ... -> 50 -> 51(Home Lane)

  final bool homeEntryPending;
  const LudoToken({
    required this.id,
    required this.playerId,
    required this.tokenIndex,
    required this.position,
    required this.positionInPath,
    required this.state,
    this.homeEntryPending = false,
  });

  bool get isFinished => state == LudoTokenState.finished;

  bool get isInitial => state == LudoTokenState.initial;

  bool get isSafe =>
      state == LudoTokenState.safe || state == LudoTokenState.safeInPair;

  LudoToken copyWith({
    String? id,
    String? playerId,
    int? tokenIndex,
    Position? position,
    int? positionInPath,
    LudoTokenState? state,
    bool? homeEntryPending,
  }) {
    return LudoToken(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      tokenIndex: tokenIndex ?? this.tokenIndex,
      position: position ?? this.position,
      positionInPath: positionInPath ?? this.positionInPath,
      state: state ?? this.state,
      homeEntryPending: homeEntryPending ?? this.homeEntryPending,
    );
  }

  @override
  List<Object?> get props => [
    id,
    playerId,
    tokenIndex,
    position,
    positionInPath,
    state,
    homeEntryPending,
  ];
}
