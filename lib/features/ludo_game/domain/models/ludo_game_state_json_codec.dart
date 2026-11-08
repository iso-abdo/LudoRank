
import 'dart:convert';

import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/position.dart';
import 'available_rolls.dart';
import 'dice_roll.dart';
import 'ludo_game_state.dart';
import 'turn_state.dart';

/// مسؤول فقط عن تحويل LudoGameState من وإلى JSON.
///
/// لا يعتمد على Provider أو Database أو UI.
class LudoGameStateJsonCodec {
  LudoGameStateJsonCodec._();

  static const int formatVersion = 1;

  /// يحول حالة اللعبة إلى JSON String.
  static String encode(LudoGameState state) {
    return jsonEncode({
      'formatVersion': formatVersion,
      'state': _stateToJson(state),
    });
  }

  /// يستعيد حالة اللعبة من JSON String.
  ///
  /// يرمي FormatException عند وجود بيانات غير صالحة
  /// أو إصدار غير مدعوم.
  static LudoGameState decode(String source) {
    try {
      final decoded = jsonDecode(source);
      final root = _asMap(decoded, 'root');

      final version = _asInt(
        root['formatVersion'],
        'formatVersion',
      );

      if (version != formatVersion) {
        throw FormatException(
          'إصدار بيانات اللعبة غير مدعوم: $version',
        );
      }

      return _stateFromJson(
        _asMap(root['state'], 'state'),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'تعذر استعادة حالة اللعبة: $error',
      );
    }
  }

  // ============================================================
  // GAME STATE
  // ============================================================

  static Map<String, dynamic> _stateToJson(
      LudoGameState state,
      ) {
    return {
      'players': state.players.map(_playerToJson).toList(),
      'currentPlayerIndex': state.currentPlayerIndex,
      'turnState': _turnStateToJson(state.turnState),
      'isStarted': state.isStarted,
      'isFinished': state.isFinished,
      'finishedPlayerIds': state.finishedPlayerIds,
    };
  }

  static LudoGameState _stateFromJson(
      Map<String, dynamic> json,
      ) {
    return LudoGameState(
      players: _asList(
        json['players'],
        'players',
      ).map(
            (item) => _playerFromJson(
          _asMap(item, 'players[]'),
        ),
      ).toList(growable: false),
      currentPlayerIndex: _asInt(
        json['currentPlayerIndex'],
        'currentPlayerIndex',
      ),
      turnState: _turnStateFromJson(
        _asMap(json['turnState'], 'turnState'),
      ),
      isStarted: _asBool(json['isStarted'], 'isStarted'),
      isFinished: _asBool(json['isFinished'], 'isFinished'),
      finishedPlayerIds: _asList(
        json['finishedPlayerIds'],
        'finishedPlayerIds',
      ).map(
            (item) => _asString(item, 'finishedPlayerIds[]'),
      ).toList(growable: false),
    );
  }

  // ============================================================
  // PLAYER
  // ============================================================

  static Map<String, dynamic> _playerToJson(
      LudoPlayer player,
      ) {
    return {
      'id': player.id,
      'playerId': player.playerId,
      'name': player.name,
      'color': player.color.name,
      'seat': player.seat,
      'tokens': player.tokens.map(_tokenToJson).toList(),
      'hasCaptured': player.hasCaptured,
    };
  }

  static LudoPlayer _playerFromJson(
      Map<String, dynamic> json,
      ) {
    return LudoPlayer(
      id: _asString(json['id'], 'player.id'),
      playerId: _asString(json['playerId'], 'player.playerId'),
      name: _asString(json['name'], 'player.name'),
      color: _enumByName(
        LudoPlayerColor.values,
        json['color'],
        'player.color',
      ),
      seat: _asInt(json['seat'], 'player.seat'),
      tokens: _asList(
        json['tokens'],
        'player.tokens',
      ).map(
            (item) => _tokenFromJson(
          _asMap(item, 'player.tokens[]'),
        ),
      ).toList(growable: false),
      hasCaptured: _asBool(
        json['hasCaptured'],
        'player.hasCaptured',
      ),
    );
  }

  // ============================================================
  // TOKEN
  // ============================================================

  static Map<String, dynamic> _tokenToJson(
      LudoToken token,
      ) {
    return {
      'id': token.id,
      'playerId': token.playerId,
      'tokenIndex': token.tokenIndex,
      'position': _positionToJson(token.position),
      'positionInPath': token.positionInPath,
      'state': token.state.name,
      'homeEntryPending': token.homeEntryPending,
    };
  }

  static LudoToken _tokenFromJson(
      Map<String, dynamic> json,
      ) {
    return LudoToken(
      id: _asString(json['id'], 'token.id'),
      playerId: _asString(json['playerId'], 'token.playerId'),
      tokenIndex: _asInt(json['tokenIndex'], 'token.tokenIndex'),
      position: _positionFromJson(
        _asMap(json['position'], 'token.position'),
      ),
      positionInPath: _asInt(
        json['positionInPath'],
        'token.positionInPath',
      ),
      state: _enumByName(
        LudoTokenState.values,
        json['state'],
        'token.state',
      ),
      homeEntryPending: _asBool(
        json['homeEntryPending'],
        'token.homeEntryPending',
      ),
    );
  }

  // ============================================================
  // POSITION
  // ============================================================

  static Map<String, dynamic> _positionToJson(
      Position position,
      ) {
    return {
      'row': position.row,
      'column': position.column,
    };
  }

  static Position _positionFromJson(
      Map<String, dynamic> json,
      ) {
    return Position(
      row: _asInt(json['row'], 'position.row'),
      column: _asInt(json['column'], 'position.column'),
    );
  }

  // ============================================================
  // TURN STATE
  // ============================================================

  static Map<String, dynamic> _turnStateToJson(
      TurnState turn,
      ) {
    return {
      'playerId': turn.playerId,
      'rolls': turn.rolls.map(_diceRollToJson).toList(),
      'availableRolls': turn.availableRolls.rolls
          .map(_diceRollToJson)
          .toList(),
      'sixRollCount': turn.sixRollCount,
      'phase': turn.phase.name,
    };
  }

  static TurnState _turnStateFromJson(
      Map<String, dynamic> json,
      ) {
    return TurnState(
      playerId: _asString(json['playerId'], 'turn.playerId'),
      rolls: _asList(
        json['rolls'],
        'turn.rolls',
      ).map(
            (item) => _diceRollFromJson(
          _asMap(item, 'turn.rolls[]'),
        ),
      ).toList(growable: false),
      availableRolls: AvailableRolls(
        rolls: _asList(
          json['availableRolls'],
          'turn.availableRolls',
        ).map(
              (item) => _diceRollFromJson(
            _asMap(item, 'turn.availableRolls[]'),
          ),
        ).toList(growable: false),
      ),
      sixRollCount: _asInt(
        json['sixRollCount'],
        'turn.sixRollCount',
      ),
      phase: _enumByName(
        TurnPhase.values,
        json['phase'],
        'turn.phase',
      ),
    );
  }

  // ============================================================
  // DICE ROLL
  // ============================================================

  static Map<String, dynamic> _diceRollToJson(
      DiceRoll roll,
      ) {
    return {
      'value': roll.value,
      'sequence': roll.sequence,
    };
  }

  static DiceRoll _diceRollFromJson(
      Map<String, dynamic> json,
      ) {
    final value = _asInt(json['value'], 'dice.value');
    final sequence = _asInt(
      json['sequence'],
      'dice.sequence',
    );

    if (value < 1 || value > 6) {
      throw FormatException('قيمة النرد غير صحيحة: $value');
    }

    if (sequence < 1) {
      throw FormatException(
        'ترتيب الرمية غير صحيح: $sequence',
      );
    }

    return DiceRoll(
      value: value,
      sequence: sequence,
    );
  }

  // ============================================================
  // JSON VALIDATION HELPERS
  // ============================================================

  static Map<String, dynamic> _asMap(
      dynamic value,
      String field,
      ) {
    if (value is! Map) {
      throw FormatException(
        'الحقل $field يجب أن يكون Object.',
      );
    }

    return Map<String, dynamic>.from(value);
  }

  static List<dynamic> _asList(
      dynamic value,
      String field,
      ) {
    if (value is! List) {
      throw FormatException(
        'الحقل $field يجب أن يكون List.',
      );
    }

    return value;
  }

  static String _asString(
      dynamic value,
      String field,
      ) {
    if (value is! String) {
      throw FormatException(
        'الحقل $field يجب أن يكون String.',
      );
    }

    return value;
  }

  static int _asInt(
      dynamic value,
      String field,
      ) {
    if (value is! int) {
      throw FormatException(
        'الحقل $field يجب أن يكون int.',
      );
    }

    return value;
  }

  static bool _asBool(
      dynamic value,
      String field,
      ) {
    if (value is! bool) {
      throw FormatException(
        'الحقل $field يجب أن يكون bool.',
      );
    }

    return value;
  }

  static T _enumByName<T extends Enum>(
      List<T> values,
      dynamic value,
      String field,
      ) {
    final name = _asString(value, field);

    for (final item in values) {
      if (item.name == name) {
        return item;
      }
    }

    throw FormatException(
      'قيمة enum غير معروفة في $field: $name',
    );
  }
}
