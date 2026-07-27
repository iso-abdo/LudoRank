import 'package:equatable/equatable.dart';

enum MatchStatus {
  waiting,
  running,
  finished,
}

class Match extends Equatable {
  final String id;

  final String tournamentId;

  final int round;

  final MatchStatus status;

  final String? winnerId;

  final DateTime createdAt;

  final DateTime updatedAt;

  const Match({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.status,
    this.winnerId,
    required this.createdAt,
    required this.updatedAt,
  });

  Match copyWith({
    String? id,
    String? tournamentId,
    int? round,
    MatchStatus? status,
    String? winnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      round: round ?? this.round,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tournamentId,
    round,
    status,
    winnerId,
    createdAt,
    updatedAt,
  ];
}