import 'package:equatable/equatable.dart';

import 'match_status.dart';

class Match extends Equatable {
  final String id;

  /// البطولة التى تنتمى إليها المباراة
  final String tournamentId;

  /// عدد اللاعبين فى المباراة
  /// (2 أو 3 أو 4)
  final int playersCount;

  /// حالة المباراة
  final MatchStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Match({
    required this.id,
    required this.tournamentId,
    required this.playersCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Match copyWith({
    String? id,
    String? tournamentId,
    int? playersCount,
    MatchStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      playersCount: playersCount ?? this.playersCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tournamentId,
    playersCount,
    status,
    createdAt,
    updatedAt,
  ];
}