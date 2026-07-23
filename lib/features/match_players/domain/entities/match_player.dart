import 'package:equatable/equatable.dart';

class MatchPlayer extends Equatable {
  final String id;

  final String matchId;

  final String playerId;

  final int seat;

  final int? rank;

  final int points;

  final bool finished;

  const MatchPlayer({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.seat,
    this.rank,
    required this.points,
    required this.finished,
  });

  MatchPlayer copyWith({
    String? id,
    String? matchId,
    String? playerId,
    int? seat,
    int? rank,
    int? points,
    bool? finished,
  }) {
    return MatchPlayer(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      seat: seat ?? this.seat,
      rank: rank ?? this.rank,
      points: points ?? this.points,
      finished: finished ?? this.finished,
    );
  }

  @override
  List<Object?> get props => [
    id,
    matchId,
    playerId,
    seat,
    rank,
    points,
    finished,
  ];
}