import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rank/core/database/database.dart';

void main() {
  late AppDatabase database;
  late MatchDao dao;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = database.matchDao;

    await database.into(database.tournaments).insert(
      TournamentsCompanion.insert(
        id: 'tournament-1',
        name: 'Test Tournament',
        rounds: 1,
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    await dao.insertMatch(
      MatchesCompanion.insert(
        id: 'match-1',
        tournamentId: 'tournament-1',
        matchNumber: 1,
        status: 'playing',
        playersCount: const Value(2),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('MatchDao game state storage', () {
    test('saves game state JSON without changing match data', () async {
      const json = '{"formatVersion":1,"state":{}}';

      final updatedRows = await dao.saveGameStateJson(
        matchId: 'match-1',
        gameStateJson: json,
      );

      final match = await dao.getMatchById('match-1');

      expect(updatedRows, 1);
      expect(match, isNotNull);
      expect(match!.gameStateJson, json);
      expect(match.status, 'playing');
      expect(match.playersCount, 2);
      expect(match.matchNumber, 1);
    });

    test('returns null when no game state is saved', () async {
      final json = await dao.getGameStateJson('match-1');

      expect(json, isNull);
    });

    test('returns saved game state JSON', () async {
      const expectedJson = '{"formatVersion":1,"state":{}}';

      await dao.saveGameStateJson(
        matchId: 'match-1',
        gameStateJson: expectedJson,
      );

      final actualJson = await dao.getGameStateJson('match-1');

      expect(actualJson, expectedJson);
    });

    test('returns zero when saving for a missing match', () async {
      final updatedRows = await dao.saveGameStateJson(
        matchId: 'missing-match',
        gameStateJson: '{}',
      );

      expect(updatedRows, 0);
    });

    test('clears game state without deleting the match', () async {
      await dao.saveGameStateJson(
        matchId: 'match-1',
        gameStateJson: '{"saved":true}',
      );

      final updatedRows = await dao.clearGameStateJson('match-1');

      final match = await dao.getMatchById('match-1');

      expect(updatedRows, 1);
      expect(match, isNotNull);
      expect(match!.gameStateJson, isNull);
      expect(match.status, 'playing');
    });

    test('returns zero when clearing a missing match', () async {
      final updatedRows = await dao.clearGameStateJson(
        'missing-match',
      );

      expect(updatedRows, 0);
    });
  });
}