import 'package:drift/drift.dart';

import 'package:ludo_rank/core/database/database.dart';

import '../../domain/entities/player.dart' as entity;

import 'package:ludo_rank/core/database/database.dart' as db;

class PlayerModel extends entity.Player {
  const PlayerModel({
    required super.id,
    required super.name,
    super.nickname,
    super.avatar,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.isActive,
  });

  factory PlayerModel.fromEntity(entity.Player entity) {
    return PlayerModel(
      id: entity.id,
      name: entity.name,
      nickname: entity.nickname,
      avatar: entity.avatar,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  factory PlayerModel.fromDrift(db.Player row) {
    return PlayerModel(
      id: row.id,
      name: row.name,
      nickname: row.nickname,
      avatar: row.avatar,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isActive: row.isActive,
    );
  }

  PlayersCompanion toCompanion() {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      nickname: Value(nickname),
      avatar: Value(avatar),
      notes: Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}