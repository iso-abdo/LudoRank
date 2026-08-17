import 'package:equatable/equatable.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';



class LudoPlayer extends Equatable {
  final String id;

  /// الـ playerId الأصلي من LudoRank
  final String playerId;

  /// اسم اللاعب للعرض
  final String name;

  /// لون اللاعب داخل اللعبة
  final LudoPlayerColor color;

  /// ترتيب اللاعب في المباراة
  final int seat;

  /// الـ tokens الخاصة باللاعب
  final List<LudoToken> tokens;

  const LudoPlayer({
    required this.id,
    required this.playerId,
    required this.name,
    required this.color,
    required this.seat,
    required this.tokens,
  });

  LudoPlayer copyWith({
    String? id,
    String? playerId,
    String? name,
    LudoPlayerColor? color,
    int? seat,
    List<LudoToken>? tokens,
  }) {
    return LudoPlayer(
      id: id ?? this.id,
      playerId:
      playerId ?? this.playerId,
      name: name ?? this.name,
      color: color ?? this.color,
      seat: seat ?? this.seat,
      tokens: tokens ?? this.tokens,
    );
  }

  @override
  List<Object?> get props => [
    id,
    playerId,
    name,
    color,
    seat,
    tokens,
  ];
}

enum LudoPlayerColor {
  red,
  green,
  yellow,
  blue,
}