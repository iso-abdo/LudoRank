import 'package:ludo_rank/features/ludo_game/domain/models/game_result.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';
import 'package:ludo_rank/features/ludo_game/domain/services/ludo_game_engine.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

import '../entities/match.dart';

/// Runtime session for one running LudoRank match.
///
/// This object connects the persisted match information with
/// the in-memory LudoGameEngine.
///
/// Important:
/// - Match contains tournament/match metadata.
/// - MatchPlayer contains persisted player participation data.
/// - LudoGameEngine contains the actual Ludo rules and runtime state.
/// - This class does NOT implement any Ludo rules.
class MatchGameSession {
  final Match match;
  final List<MatchPlayer> matchPlayers;
  final LudoGameEngine engine;

   MatchGameSession({
    required this.match,
    required List<MatchPlayer> matchPlayers,
    required this.engine,
  }) : matchPlayers =   List.unmodifiable(matchPlayers);

  /// Current runtime Ludo state.
  LudoGameState get state => engine.state;

  /// Whether the underlying Ludo match has started.
  bool get isStarted => engine.isStarted;

  /// Whether the underlying Ludo match has completely finished.
  bool get isFinished => engine.isFinished;

  /// Current player according to the Ludo engine.
  String get currentPlayerId => engine.currentPlayer.playerId;

  /// Current GameResult produced by the Ludo engine.
  ///
  /// This should normally be consumed only after the engine
  /// reports that the game is finished.
  GameResult get result => engine.getResult();

  /// Finds a MatchPlayer by its original playerId.
  MatchPlayer? getMatchPlayer(String playerId) {
    for (final matchPlayer in matchPlayers) {
      if (matchPlayer.playerId == playerId) {
        return matchPlayer;
      }
    }

    return null;
  }
}