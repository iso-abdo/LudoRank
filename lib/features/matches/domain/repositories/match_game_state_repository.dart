import 'package:ludo_rank/features/ludo_game/domain/models/ludo_game_state.dart';

abstract interface class MatchGameStateRepository {
  /// حفظ الحالة الحالية للمباراة.
  Future<void> saveGameState({
    required String matchId,
    required LudoGameState state,
  });

  /// استعادة الحالة المحفوظة.
  ///
  /// يرجع null إذا لم توجد حالة محفوظة.
  Future<LudoGameState?> loadGameState(String matchId);

  /// مسح الحالة المحفوظة دون حذف المباراة.
  Future<void> clearGameState(String matchId);
}