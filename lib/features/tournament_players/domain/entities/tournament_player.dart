import 'package:equatable/equatable.dart';

class TournamentPlayer extends Equatable {
  final String id;

  final String tournamentId;

  final String playerId;

  final DateTime joinedAt;

  const TournamentPlayer({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [
    id,
    tournamentId,
    playerId,
    joinedAt,
  ];
}