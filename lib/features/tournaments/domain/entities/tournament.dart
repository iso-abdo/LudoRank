import 'package:equatable/equatable.dart';

enum TournamentStatus {
  draft,
  ready,
  running,
  finished,
  cancelled,
}

class Tournament extends Equatable {
  final String id;

  final String name;

  final TournamentStatus status;

  final int rounds;

  final DateTime createdAt;

  final DateTime updatedAt;

  const Tournament({
    required this.id,
    required this.name,
    required this.status,
    required this.rounds,
    required this.createdAt,
    required this.updatedAt,
  });

  Tournament copyWith({
    String? id,
    String? name,
    TournamentStatus? status,
    int? rounds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      rounds: rounds ?? this.rounds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    rounds,
    createdAt,
    updatedAt,
  ];
}