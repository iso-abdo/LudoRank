import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/position.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/available_rolls.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/dice_roll.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/turn_state.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/domain/services/match_game_state_validator.dart';

void main() {
  group('MatchGameStateValidator', () {
    late Match match;
    late List<MatchPlayer> matchPlayers;
    late MatchGameStateValidator validator;

    setUp(() {
      final now = DateTime(2026, 1, 1);

      match = Match(
        id: 'match-1',
        tournamentId: 'tournament-1',
        playersCount: 2,
        status: MatchStatus.playing,
        createdAt: now,
        updatedAt: now,
      );

      matchPlayers = [
        _matchPlayer(playerId: 'player-1', seat: 1),
        _matchPlayer(playerId: 'player-2', seat: 2),
      ];

      validator = const MatchGameStateValidator();
    });

    void validate(LudoGameState state) {
      validator.validate(
        match: match,
        matchPlayers: matchPlayers,
        state: state,
      );
    }

    test('accepts a valid rolling state with capture bonus roll', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [
          DiceRoll(value: 6, sequence: 1),
          DiceRoll(value: 4, sequence: 2),
        ],
        availableRolls: const [DiceRoll(value: 6, sequence: 1)],
        sixRollCount: 1,
      );

      expect(() => validate(state), returnsNormally);
    });

    test('accepts a valid playing state', () {
      final state = _state(
        phase: TurnPhase.playing,
        rolls: const [
          DiceRoll(value: 3, sequence: 1),
          DiceRoll(value: 6, sequence: 2),
        ],
        availableRolls: const [
          DiceRoll(value: 3, sequence: 1),
          DiceRoll(value: 6, sequence: 2),
        ],
        sixRollCount: 1,
      );

      expect(() => validate(state), returnsNormally);
    });

    test('accepts an initial rolling state without any rolls', () {
      final state = _state(phase: TurnPhase.rolling);

      expect(() => validate(state), returnsNormally);
    });

    test('rejects a snapshot that has not started', () {
      final state = _state(isStarted: false);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a finished game state', () {
      final state = _state(isFinished: true);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects an invalid current player index', () {
      final state = _state(currentPlayerIndex: 2);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a turn player different from current player', () {
      final state = _state(turnPlayerId: 'player-2');

      expect(() => validate(state), throwsStateError);
    });

    test('rejects duplicate players in snapshot', () {
      final state = _state(
        players: [
          _ludoPlayer(playerId: 'player-1', seat: 1),
          _ludoPlayer(playerId: 'player-1', seat: 2),
        ],
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a player missing from MatchPlayers', () {
      final state = _state(
        players: [
          _ludoPlayer(playerId: 'player-1', seat: 1),
          _ludoPlayer(playerId: 'player-3', seat: 2),
        ],
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a player seat mismatch', () {
      final state = _state(
        players: [
          _ludoPlayer(playerId: 'player-1', seat: 2),
          _ludoPlayer(playerId: 'player-2', seat: 1),
        ],
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a token owned by another player', () {
      final state = _state(
        players: [
          _ludoPlayer(
            playerId: 'player-1',
            seat: 1,
            tokens: [
              _token(id: 'token-1', playerId: 'player-2', tokenIndex: 0),
            ],
          ),
          _ludoPlayer(playerId: 'player-2', seat: 2),
        ],
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects duplicate token IDs', () {
      final state = _state(
        players: [
          _ludoPlayer(
            playerId: 'player-1',
            seat: 1,
            tokens: [_token(id: 'duplicate-token', playerId: 'player-1')],
          ),
          _ludoPlayer(
            playerId: 'player-2',
            seat: 2,
            tokens: [_token(id: 'duplicate-token', playerId: 'player-2')],
          ),
        ],
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a gap in dice roll sequences', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [
          DiceRoll(value: 6, sequence: 1),
          DiceRoll(value: 4, sequence: 3),
        ],
        availableRolls: const [DiceRoll(value: 6, sequence: 1)],
        sixRollCount: 1,
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects an available roll absent from roll history', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [DiceRoll(value: 6, sequence: 1)],
        availableRolls: const [DiceRoll(value: 4, sequence: 2)],
        sixRollCount: 1,
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects an available roll with a different value', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [DiceRoll(value: 6, sequence: 1)],
        availableRolls: const [DiceRoll(value: 5, sequence: 1)],
        sixRollCount: 1,
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects duplicate available roll sequences', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [
          DiceRoll(value: 6, sequence: 1),
          DiceRoll(value: 4, sequence: 2),
        ],
        availableRolls: const [
          DiceRoll(value: 6, sequence: 1),
          DiceRoll(value: 6, sequence: 1),
        ],
        sixRollCount: 1,
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects sixRollCount inconsistent with roll history', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [
          DiceRoll(value: 6, sequence: 1),
          DiceRoll(value: 4, sequence: 2),
          DiceRoll(value: 6, sequence: 3),
        ],
        availableRolls: const [DiceRoll(value: 6, sequence: 1)],
        sixRollCount: 1,
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects a third six in an active turn', () {
      final state = _state(
        phase: TurnPhase.rolling,
        rolls: const [
          DiceRoll(value: 6, sequence: 1),
          DiceRoll(value: 4, sequence: 2),
          DiceRoll(value: 6, sequence: 3),
          DiceRoll(value: 2, sequence: 4),
          DiceRoll(value: 6, sequence: 5),
        ],
        availableRolls: const [],
        sixRollCount: 3,
      );

      expect(() => validate(state), throwsStateError);
    });

    test('rejects playing phase without available rolls', () {
      final state = _state(phase: TurnPhase.playing);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects cancelled phase as an active snapshot', () {
      final state = _state(phase: TurnPhase.cancelled);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects completed phase as an active snapshot', () {
      final state = _state(phase: TurnPhase.completed);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects an unknown finished player', () {
      final state = _state(finishedPlayerIds: const ['unknown-player']);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects duplicate finished player IDs', () {
      final state = _state(finishedPlayerIds: const ['player-1', 'player-1']);

      expect(() => validate(state), throwsStateError);
    });

    test('rejects an active match with enough finishers to end it', () {
      final state = _state(
        finishedPlayerIds: const ['player-1'],
        players: [
          _ludoPlayer(
            playerId: 'player-1',
            seat: 1,
            tokens: [
              _token(
                id: 'finished-token',
                playerId: 'player-1',
                state: LudoTokenState.finished,
                positionInPath: 56,
              ),
            ],
          ),
          _ludoPlayer(playerId: 'player-2', seat: 2),
        ],
      );

      expect(() => validate(state), throwsStateError);
    });
  });
}

MatchPlayer _matchPlayer({required String playerId, required int seat}) {
  return MatchPlayer(
    id: 'mp-$playerId',
    matchId: 'match-1',
    playerId: playerId,
    seat: seat,
    rank: null,
    points: 0,
    finished: false,
  );
}

LudoGameState _state({
  bool isStarted = true,
  bool isFinished = false,
  int currentPlayerIndex = 0,
  String? turnPlayerId,
  TurnPhase phase = TurnPhase.rolling,
  List<DiceRoll> rolls = const [],
  List<DiceRoll> availableRolls = const [],
  int sixRollCount = 0,
  List<String> finishedPlayerIds = const [],
  List<LudoPlayer>? players,
}) {
  final actualPlayers =
      players ??
      [
        _ludoPlayer(playerId: 'player-1', seat: 1),
        _ludoPlayer(playerId: 'player-2', seat: 2),
      ];

  final currentPlayerId =
      currentPlayerIndex >= 0 && currentPlayerIndex < actualPlayers.length
      ? actualPlayers[currentPlayerIndex].playerId
      : 'player-1';

  return LudoGameState(
    players: actualPlayers,
    currentPlayerIndex: currentPlayerIndex,
    isStarted: isStarted,
    isFinished: isFinished,
    finishedPlayerIds: finishedPlayerIds,
    turnState: TurnState(
      playerId: turnPlayerId ?? currentPlayerId,
      rolls: rolls,
      availableRolls: AvailableRolls(rolls: availableRolls),
      sixRollCount: sixRollCount,
      phase: phase,
    ),
  );
}

LudoPlayer _ludoPlayer({
  required String playerId,
  required int seat,
  List<LudoToken>? tokens,
}) {
  return LudoPlayer(
    id: 'ludo-$playerId',
    playerId: playerId,
    name: 'Name $playerId',
    color: seat == 1 ? LudoPlayerColor.green : LudoPlayerColor.blue,
    seat: seat,
    tokens:
        tokens ??
        List.generate(
          4,
          (index) => _token(
            id: '$playerId-token-$index',
            playerId: playerId,
            tokenIndex: index,
          ),
        ),
  );
}

LudoToken _token({
  required String id,
  required String playerId,
  int tokenIndex = 0,
  LudoTokenState state = LudoTokenState.initial,
  int positionInPath = -1,
}) {
  return LudoToken(
    id: id,
    playerId: playerId,
    tokenIndex: tokenIndex,
    position: const Position(row: 0, column: 0),
    positionInPath: positionInPath,
    state: state,
  );
}
