import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rank/core/database/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory tempDirectory;
  late File databaseFile;
  late AppDatabase database;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'ludorank_migration_test_',
    );

    databaseFile = File('${tempDirectory.path}/ludorank_v2.db');

    _createVersion2Database(databaseFile.path);

    database = AppDatabase.forTesting(NativeDatabase(databaseFile));
  });

  tearDown(() async {
    await database.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('migrates schema 2 to schema 3 and preserves old data', () async {
    // Opening the database triggers Drift migration.
    final matches = await database.select(database.matches).get();
    final players = await database.select(database.players).get();
    final tournaments = await database.select(database.tournaments).get();
    final matchPlayers = await database.select(database.matchPlayers).get();

    // Verify existing records were preserved.
    expect(tournaments, hasLength(1));
    expect(tournaments.single.id, 'tournament-1');
    expect(tournaments.single.name, 'Migration Tournament');

    expect(players, hasLength(2));
    expect(players.map((player) => player.id).toSet(), {
      'player-1',
      'player-2',
    });

    expect(matches, hasLength(1));
    expect(matches.single.id, 'match-1');
    expect(matches.single.tournamentId, 'tournament-1');
    expect(matches.single.status, 'playing');

    expect(matchPlayers, hasLength(2));

    // Verify the value from schema 2 was preserved.
    expect(matches.single.playersCount, 2);

    // Old matches must not have a snapshot automatically.
    expect(matches.single.gameStateJson, isNull);

    // Verify SQLite's actual schema version.
    final versionRow = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(versionRow.read<int>('user_version'), 3);

    // Verify the new column physically exists.
    final columns = await database
        .customSelect('PRAGMA table_info(matches)')
        .get();

    final columnNames = columns.map((row) => row.read<String>('name')).toSet();

    expect(columnNames, contains('game_state_json'));
  });
}

/// Creates a real SQLite database using the old schema (version 2).
///
/// This intentionally does not use the current Drift table definitions.
/// It simulates a database created by the previous application version.
void _createVersion2Database(String path) {
  final oldDatabase = sqlite.sqlite3.open(path);

  try {
    oldDatabase.execute('PRAGMA foreign_keys = ON');

    oldDatabase.execute('''
      CREATE TABLE players (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        nickname TEXT,
        avatar TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    oldDatabase.execute('''
      CREATE TABLE tournaments (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        rounds INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    oldDatabase.execute('''
      CREATE TABLE tournament_players (
        id TEXT NOT NULL,
        tournament_id TEXT NOT NULL
          REFERENCES tournaments (id),
        player_id TEXT NOT NULL
          REFERENCES players (id),
        joined_at INTEGER NOT NULL
      )
    ''');

    oldDatabase.execute('''
      CREATE TABLE matches (
        id TEXT NOT NULL PRIMARY KEY,
        tournament_id TEXT NOT NULL
          REFERENCES tournaments (id),
        match_number INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        players_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    oldDatabase.execute('''
      CREATE TABLE match_players (
        id TEXT NOT NULL PRIMARY KEY,
        match_id TEXT NOT NULL
          REFERENCES matches (id),
        player_id TEXT NOT NULL
          REFERENCES players (id),
        seat INTEGER NOT NULL,
        rank INTEGER,
        points INTEGER NOT NULL DEFAULT 0,
        finished INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert old tournament.
    oldDatabase.execute('''
      INSERT INTO tournaments (
        id, name, rounds, status, created_at, updated_at
      ) VALUES (
        'tournament-1',
        'Migration Tournament',
        3,
        'active',
        1760000000,
        1760000000
      )
    ''');

    // Insert old players.
    oldDatabase.execute('''
      INSERT INTO players (
        id, name, is_active, created_at, updated_at
      ) VALUES (
        'player-1',
        'Player One',
        1,
        1760000000,
        1760000000
      )
    ''');

    oldDatabase.execute('''
      INSERT INTO players (
        id, name, is_active, created_at, updated_at
      ) VALUES (
        'player-2',
        'Player Two',
        1,
        1760000000,
        1760000000
      )
    ''');

    // Insert old match with players_count = 2.
    oldDatabase.execute('''
      INSERT INTO matches (
        id,
        tournament_id,
        match_number,
        status,
        created_at,
        updated_at,
        players_count
      ) VALUES (
        'match-1',
        'tournament-1',
        1,
        'playing',
        1760000000,
        1760000000,
        2
      )
    ''');

    // Insert match participants.
    oldDatabase.execute('''
      INSERT INTO match_players (
        id, match_id, player_id, seat, points, finished
      ) VALUES (
        'match-player-1',
        'match-1',
        'player-1',
        0,
        0,
        0
      )
    ''');

    oldDatabase.execute('''
      INSERT INTO match_players (
        id, match_id, player_id, seat, points, finished
      ) VALUES (
        'match-player-2',
        'match-1',
        'player-2',
        1,
        0,
        0
      )
    ''');

    // Mark this file as a version 2 database.
    oldDatabase.execute('PRAGMA user_version = 2');
  } finally {
    oldDatabase.close();
  }
}
