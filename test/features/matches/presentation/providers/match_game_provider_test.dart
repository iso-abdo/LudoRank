import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/domain/services/ludo_game_engine.dart';

import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/domain/repositories/match_repository.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_service.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_session.dart';

import 'package:ludo_rank/features/matches/presentation/providers/match_game_provider.dart';

import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/dice_roll.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';

void main() {
  group('MatchGameProvider', () {
    late FakeMatchRepository matchRepository;
    late FakeMatchPlayerRepository matchPlayerRepository;
    late FakeMatchGameService service;
    late MatchGameProvider provider;

    late Match match;
    late List<MatchPlayer> matchPlayers;

    const playerNames = {'player-1': 'Player 1', 'player-2': 'Player 2'};

    setUp(() {
      matchRepository = FakeMatchRepository();
      matchPlayerRepository = FakeMatchPlayerRepository();

      service = FakeMatchGameService(
        matchRepository: matchRepository,
        matchPlayerRepository: matchPlayerRepository,
      );

      provider = MatchGameProvider(service: service);

      final now = DateTime(2026, 1, 1);

      match = Match(
        id: 'match-1',
        tournamentId: 'tournament-1',
        playersCount: 2,
        status: MatchStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      matchPlayers = [
        MatchPlayer(
          id: 'mp-1',
          matchId: 'match-1',
          playerId: 'player-1',
          seat: 1,
          rank: null,
          points: 0,
          finished: false,
        ),
        MatchPlayer(
          id: 'mp-2',
          matchId: 'match-1',
          playerId: 'player-2',
          seat: 2,
          rank: null,
          points: 0,
          finished: false,
        ),
      ];

      matchRepository.seed(match);
      matchPlayerRepository.seed(matchPlayers);
    });

    // ==========================================================
    // START MATCH
    // ==========================================================

    test('startMatch creates session and changes status to playing', () async {
      final session = createSession(
        match: match.copyWith(status: MatchStatus.playing),
      );

      service.startSession = session;

      var notifications = 0;

      provider.addListener(() {
        notifications++;
      });

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      expect(provider.session, same(session));

      expect(provider.matchStatus, MatchStatus.playing);

      expect(provider.isStarted, isTrue);

      expect(provider.isPlaying, isTrue);

      expect(provider.isFinished, isFalse);

      expect(provider.error, isNull);

      expect(service.startMatchCallCount, 1);

      expect(notifications, greaterThan(0));
    });

    // ==========================================================
    // START MATCH ERROR
    // ==========================================================

    test('startMatch stores service error and restores idle state', () async {
      service.startMatchError = StateError('cannot start');

      var notifications = 0;

      provider.addListener(() {
        notifications++;
      });

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      // الخدمة استُدعيت مرة واحدة وفشلت.
      expect(service.startMatchCallCount, 1);

      // لا توجد جلسة أو مباراة بدأت بنجاح.
      expect(provider.session, isNull);
      expect(provider.matchStatus, isNull);
      expect(provider.isStarted, isFalse);
      expect(provider.isPlaying, isFalse);
      expect(provider.isFinished, isFalse);

      // الخطأ محفوظ، والتحميل انتهى.
      expect(provider.error, contains('cannot start'));
      expect(provider.isLoading, isFalse);

      // الواجهة تلقت إشعارات بتغيّر الحالة.
      expect(notifications, greaterThan(0));
    });

    // ==========================================================
    // SELECT TOKEN
    // ==========================================================

    test('selectToken changes UI selection only', () async {
      final session = createSession(
        match: match.copyWith(status: MatchStatus.playing),
      );

      service.startSession = session;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      provider.selectToken('player-1-token-0');

      expect(provider.selectedTokenId, 'player-1-token-0');

      expect(session.state.players[0].tokens[0].positionInPath, -1);

      provider.selectToken('player-1-token-0');

      expect(provider.selectedTokenId, isNull);
    });

    // ==========================================================
    // ROLL DICE
    // ==========================================================

    test('rollDice delegates to the Ludo engine', () async {
      final engine = FakeLudoGameEngine(initialState: createStartedState());

      final session = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      service.startSession = session;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      provider.rollDice();

      expect(engine.rollDiceCallCount, 1);

      expect(provider.error, isNull);
    });

    // ==========================================================
    // ROLL DICE ERROR
    // ==========================================================

    test('rollDice stores engine error', () async {
      final engine = FakeLudoGameEngine(
        initialState: createStartedState(),
        rollDiceError: StateError('dice error'),
      );

      final session = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      service.startSession = session;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      provider.rollDice();

      expect(provider.error, contains('dice error'));
    });

    // ==========================================================
    // EXECUTE MOVE
    // ==========================================================

    test('executeMove delegates move to the Ludo engine', () async {
      final engine = FakeLudoGameEngine(initialState: createStartedState());

      final session = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      service.startSession = session;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      provider.selectToken('player-1-token-0');

      final move = MoveToken(
        tokenId: 'player-1-token-0',
        steps: 1,
        rollSequence: 1,
      );

      await provider.executeMove(move);

      expect(engine.executeMoveCallCount, 1);

      expect(engine.lastMove, same(move));

      expect(provider.selectedTokenId, isNull);
      expect(provider.selectedRollSequence, isNull);

      expect(provider.error, isNull);
    });

    // ==========================================================
    // EXECUTE MOVE -> FINISHED
    // ==========================================================

    test('executeMove automatically completes the finished match', () async {
      final engine = FakeLudoGameEngine(
        initialState: createStartedState(),
        finishAfterMove: true,
      );

      final session = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      final completedPlayers = [
        MatchPlayer(
          id: 'mp-1',
          matchId: match.id,
          playerId: 'player-1',
          seat: 1,
          rank: 1,
          points: 2,
          finished: true,
        ),
        MatchPlayer(
          id: 'mp-2',
          matchId: match.id,
          playerId: 'player-2',
          seat: 2,
          rank: 2,
          points: 1,
          finished: true,
        ),
      ];

      service.startSession = session;
      service.completeMatchResult = completedPlayers;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      await provider.executeMove(
        MoveToken(tokenId: 'player-1-token-0', steps: 1, rollSequence: 1),
      );

      expect(engine.isFinished, isTrue);

      expect(service.completeMatchCallCount, 1);

      expect(provider.isGameFinished, isTrue);

      expect(provider.isFinished, isTrue);

      expect(provider.matchStatus, MatchStatus.finished);

      expect(provider.completedPlayers, orderedEquals(completedPlayers));

      expect(provider.error, isNull);
      expect(provider.selectedTokenId, isNull);
      expect(provider.selectedRollSequence, isNull);
    });

    // ==========================================================
    // RETRY PERSISTENCE وقبل
    // ==========================================================

    test(
      'executeMove preserves finished game when persistence fails and allows retry',
      () async {
        final engine = FakeLudoGameEngine(
          initialState: createStartedState(),
          finishAfterMove: true,
        );

        final session = MatchGameSession(
          match: match.copyWith(status: MatchStatus.playing),
          matchPlayers: matchPlayers,
          engine: engine,
        );

        final completedPlayers = [
          MatchPlayer(
            id: 'mp-1',
            matchId: match.id,
            playerId: 'player-1',
            seat: 1,
            rank: 1,
            points: 2,
            finished: true,
          ),
          MatchPlayer(
            id: 'mp-2',
            matchId: match.id,
            playerId: 'player-2',
            seat: 2,
            rank: 2,
            points: 1,
            finished: true,
          ),
        ];

        service.startSession = session;
        // لا نضبط completeMatchResult، حتى تفشل أول محاولة للحفظ.

        await provider.startMatch(matchId: match.id, playerNames: playerNames);

        await provider.executeMove(
          MoveToken(tokenId: 'player-1-token-0', steps: 1, rollSequence: 1),
        );

        // الحركة أنهت اللعبة، رغم فشل حفظ النتيجة.
        expect(engine.executeMoveCallCount, 1);
        expect(provider.isGameFinished, isTrue);
        expect(provider.result, isNotNull);

        // حالة المباراة لم تُسجل Finished لأن الحفظ فشل.
        expect(service.completeMatchCallCount, 1);
        expect(provider.matchStatus, MatchStatus.playing);
        expect(provider.isPlaying, isTrue);
        expect(provider.isFinished, isFalse);

        // الخطأ ظاهر، والتحميل انتهى، ولا توجد نتيجة محفوظة في المزود.
        expect(
          provider.error,
          contains('Fake completeMatchResult was not configured'),
        );
        expect(provider.isLoading, isFalse);
        expect(provider.completedPlayers, isEmpty);

        // اختيار الحركة تم مسحه، ولن نحتاج لتنفيذها مرة ثانية.
        expect(provider.selectedTokenId, isNull);
        expect(provider.selectedRollSequence, isNull);

        // نجهز نتيجة الحفظ ثم نعيد المحاولة.
        service.completeMatchResult = completedPlayers;

        await provider.retryFinishPersistence();

        // تمت إعادة محاولة الحفظ فقط، دون إعادة تنفيذ الحركة.
        expect(service.completeMatchCallCount, 2);
        expect(engine.executeMoveCallCount, 1);

        expect(provider.isGameFinished, isTrue);
        expect(provider.isFinished, isTrue);
        expect(provider.isPlaying, isFalse);
        expect(provider.matchStatus, MatchStatus.finished);
        expect(provider.completedPlayers, orderedEquals(completedPlayers));

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
      },
    );

    // RETRY PERSISTENCE
    // ==========================================================

    test('retryFinishPersistence completes a finished game', () async {
      final engine = FakeLudoGameEngine(
        initialState: createStartedState(),
        forceFinished: true,
      );

      final session = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      final completedPlayers = [
        MatchPlayer(
          id: 'mp-1',
          matchId: match.id,
          playerId: 'player-1',
          seat: 1,
          rank: 1,
          points: 2,
          finished: true,
        ),
        MatchPlayer(
          id: 'mp-2',
          matchId: match.id,
          playerId: 'player-2',
          seat: 2,
          rank: 2,
          points: 1,
          finished: true,
        ),
      ];

      service.startSession = session;
      service.completeMatchResult = completedPlayers;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      await provider.retryFinishPersistence();

      expect(service.completeMatchCallCount, 1);

      expect(provider.matchStatus, MatchStatus.finished);

      expect(provider.completedPlayers, orderedEquals(completedPlayers));

      expect(provider.error, isNull);
    });

    // ==========================================================
    // RETRY FINISH - NOT FINISHED
    // ==========================================================

    test('retryFinishPersistence rejects unfinished game', () async {
      final session = createSession(
        match: match.copyWith(status: MatchStatus.playing),
      );

      service.startSession = session;

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      await provider.retryFinishPersistence();

      expect(provider.error, contains('لا يمكن إعادة حفظ النتيجة'));

      expect(service.completeMatchCallCount, 0);

      expect(provider.matchStatus, MatchStatus.playing);
    });

    // ==========================================================
    // CLEAR ERROR
    // ==========================================================

    test('clearError removes current error', () async {
      service.startMatchError = StateError('test error');

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });

    // ==========================================================
    // CLEAR SELECTION
    // ==========================================================

    test('clearSelection clears selected token and roll sequence', () async {
      final players = createStartedState().players;

      final firstPlayer = players.first.copyWith(
        tokens: [
          players.first.tokens.first.copyWith(
            positionInPath: 0,
            state: LudoTokenState.normal,
          ),
          ...players.first.tokens.skip(1),
        ],
      );

      const roll = DiceRoll(value: 1, sequence: 1);

      final engine = LudoGameEngine(
        initialState: createStartedState().copyWith(
          players: [firstPlayer, players.last],
          turnState: const TurnState(
            playerId: 'player-1',
            rolls: [roll],
            availableRolls: AvailableRolls(rolls: [roll]),
            phase: TurnPhase.playing,
          ),
        ),
      );

      service.startSession = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      // نحدد الرمية أولًا؛ بدون تحديد توكن.
      await provider.handleAvailableRollTap(1);

      expect(provider.selectedRollSequence, 1);

      // نحدد التوكن بعد اختيار الرمية.
      provider.selectToken('player-1-token-0');

      expect(provider.selectedTokenId, 'player-1-token-0');
      expect(provider.selectedRollSequence, 1);

      // نتأكد إن المسح يلغي التحديدين فعلًا.
      provider.clearSelection();

      expect(provider.selectedTokenId, isNull);
      expect(provider.selectedRollSequence, isNull);
    });

    // ==========================================================
    // RESET
    // ==========================================================

    test('reset clears runtime and UI state', () async {
      final engine = FakeLudoGameEngine(
        initialState: createStartedState(),
        forceFinished: true,
      );

      final session = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      service.startSession = session;

      service.completeMatchResult = [
        MatchPlayer(
          id: 'mp-1',
          matchId: match.id,
          playerId: 'player-1',
          seat: 1,
          rank: 1,
          points: 2,
          finished: true,
        ),
        MatchPlayer(
          id: 'mp-2',
          matchId: match.id,
          playerId: 'player-2',
          seat: 2,
          rank: 2,
          points: 1,
          finished: true,
        ),
      ];

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      provider.selectToken('player-1-token-0');

      await provider.retryFinishPersistence();

      expect(provider.matchStatus, MatchStatus.finished);

      provider.reset();

      expect(provider.session, isNull);

      expect(provider.matchStatus, isNull);

      expect(provider.selectedTokenId, isNull);
      expect(provider.selectedRollSequence, isNull);

      expect(provider.completedPlayers, isEmpty);

      expect(provider.error, isNull);

      expect(provider.isLoading, isFalse);
    });
    // ==========================================================
    // HANDLE AVAILABLE ROLL TAP
    // ==========================================================
    test('reset clears selected roll sequence', () async {
      final players = createStartedState().players;

      final firstPlayer = players.first.copyWith(
        tokens: [
          players.first.tokens.first.copyWith(
            positionInPath: 0,
            state: LudoTokenState.normal,
          ),
          ...players.first.tokens.skip(1),
        ],
      );

      const roll = DiceRoll(value: 1, sequence: 1);

      final engine = LudoGameEngine(
        initialState: createStartedState().copyWith(
          players: [firstPlayer, players.last],
          turnState: const TurnState(
            playerId: 'player-1',
            rolls: [roll],
            availableRolls: AvailableRolls(rolls: [roll]),
            phase: TurnPhase.playing,
          ),
        ),
      );

      service.startSession = MatchGameSession(
        match: match.copyWith(status: MatchStatus.playing),
        matchPlayers: matchPlayers,
        engine: engine,
      );

      await provider.startMatch(matchId: match.id, playerNames: playerNames);

      await provider.handleAvailableRollTap(1);

      expect(provider.selectedRollSequence, isNotNull);

      provider.reset();

      expect(provider.selectedRollSequence, isNull);
    });
  });
}

// =====================================================================
// HELPERS
// =====================================================================

LudoGameState createStartedState() {
  final players = [
    createLudoPlayer(
      playerId: 'player-1',
      seat: 1,
      color: LudoPlayerColor.green,
    ),
    createLudoPlayer(
      playerId: 'player-2',
      seat: 2,
      color: LudoPlayerColor.yellow,
    ),
  ];

  return LudoGameState.initial(players: players).copyWith(isStarted: true);
}

LudoPlayer createLudoPlayer({
  required String playerId,
  required int seat,
  required LudoPlayerColor color,
}) {
  return LudoPlayer(
    id: 'ludo-$playerId',
    playerId: playerId,
    name: playerId,
    color: color,
    seat: seat,
    tokens: List.generate(4, (index) {
      return LudoToken(
        id: '$playerId-token-$index',
        playerId: playerId,
        tokenIndex: index,
        position: const Position(row: 0, column: 0),
        positionInPath: -1,
        state: LudoTokenState.initial,
      );
    }),
  );
}

MatchGameSession createSession({required Match match, LudoGameEngine? engine}) {
  final players = [
    MatchPlayer(
      id: 'mp-1',
      matchId: match.id,
      playerId: 'player-1',
      seat: 1,
      rank: null,
      points: 0,
      finished: false,
    ),
    MatchPlayer(
      id: 'mp-2',
      matchId: match.id,
      playerId: 'player-2',
      seat: 2,
      rank: null,
      points: 0,
      finished: false,
    ),
  ];

  return MatchGameSession(
    match: match,
    matchPlayers: players,
    engine: engine ?? FakeLudoGameEngine(initialState: createStartedState()),
  );
}

// =====================================================================
// FAKE MATCH GAME SERVICE
// =====================================================================

class FakeMatchGameService extends MatchGameService {
  FakeMatchGameService({
    required super.matchRepository,
    required super.matchPlayerRepository,
  });

  MatchGameSession? startSession;

  StateError? startMatchError;

  List<MatchPlayer>? completeMatchResult;

  int startMatchCallCount = 0;

  int completeMatchCallCount = 0;

  @override
  Future<MatchGameSession> startMatch({
    required String matchId,
    required Map<String, String> playerNames,
    Random? random,
  }) async {
    startMatchCallCount++;

    if (startMatchError != null) {
      throw startMatchError!;
    }

    final session = startSession;

    if (session == null) {
      throw StateError('Fake startSession was not configured.');
    }

    return session;
  }

  @override
  Future<List<MatchPlayer>> completeMatch(MatchGameSession session) async {
    completeMatchCallCount++;

    final result = completeMatchResult;

    if (result == null) {
      throw StateError('Fake completeMatchResult was not configured.');
    }

    return List.unmodifiable(result);
  }
}

// =====================================================================
// FAKE LUDO ENGINE
// =====================================================================

class FakeLudoGameEngine extends LudoGameEngine {
  FakeLudoGameEngine({
    required super.initialState,
    this.rollDiceError,
    this.finishAfterMove = false,
    this.forceFinished = false,
  });

  final StateError? rollDiceError;

  final bool finishAfterMove;

  final bool forceFinished;

  bool _finished = false;

  int rollDiceCallCount = 0;

  int executeMoveCallCount = 0;

  MoveOption? lastMove;

  @override
  bool get isFinished {
    return _finished || forceFinished;
  }

  @override
  List<MoveOption> rollDice() {
    rollDiceCallCount++;

    if (rollDiceError != null) {
      throw rollDiceError!;
    }

    return const [];
  }

  @override
  LudoGameState executeMove(MoveOption move) {
    executeMoveCallCount++;

    lastMove = move;

    if (finishAfterMove) {
      _finished = true;
    }

    return state;
  }

  @override
  GameResult getResult() {
    return const GameResult(
      players: [
        GamePlayerResult(playerId: 'player-1', rank: 1, finished: true),
        GamePlayerResult(playerId: 'player-2', rank: 2, finished: true),
      ],
      isFinished: true,
    );
  }
}

// =====================================================================
// FAKE MATCH REPOSITORY
// =====================================================================

class FakeMatchRepository implements MatchRepository {
  final Map<String, Match> _matches = {};

  void seed(Match match) {
    _matches[match.id] = match;
  }

  @override
  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    return _matches.values
        .where((match) => match.tournamentId == tournamentId)
        .toList();
  }

  @override
  Future<List<Match>> getAllMatches() async {
    return _matches.values.toList();
  }

  @override
  Future<Match?> getById(String id) async {
    return _matches[id];
  }

  @override
  Future<void> create(Match match) async {
    _matches[match.id] = match;
  }

  @override
  Future<void> update(Match match) async {
    _matches[match.id] = match;
  }

  @override
  Future<void> delete(String id) async {
    _matches.remove(id);
  }
}

// =====================================================================
// FAKE MATCH PLAYER REPOSITORY
// =====================================================================

class FakeMatchPlayerRepository implements MatchPlayerRepository {
  final Map<String, MatchPlayer> _players = {};

  void seed(List<MatchPlayer> players) {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<List<MatchPlayer>> getMatchPlayers(String matchId) async {
    final result = _players.values
        .where((player) => player.matchId == matchId)
        .toList();

    result.sort((a, b) => a.seat.compareTo(b.seat));

    return result;
  }

  @override
  Future<MatchPlayer?> getMatchPlayer(String id) async {
    return _players[id];
  }

  @override
  Future<void> addPlayer(MatchPlayer player) async {
    _players[player.id] = player;
  }

  @override
  Future<void> addPlayers(List<MatchPlayer> players) async {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<void> updateMatchPlayer(MatchPlayer player) async {
    _players[player.id] = player;
  }

  @override
  Future<void> updateMatchPlayers(List<MatchPlayer> players) async {
    for (final player in players) {
      _players[player.id] = player;
    }
  }

  @override
  Future<void> removePlayer(String id) async {
    _players.remove(id);
  }

  @override
  Future<void> removeMatchPlayers(String matchId) async {
    final ids = _players.values
        .where((player) => player.matchId == matchId)
        .map((player) => player.id)
        .toList();

    for (final id in ids) {
      _players.remove(id);
    }
  }
}
