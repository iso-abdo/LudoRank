import '../entities/match.dart';

abstract interface class MatchRepository {
  /// جميع مباريات بطولة معينة
  Future<List<Match>> getTournamentMatches(
      String tournamentId,
      );

  /// مباراة واحدة
  Future<Match?> getById(
      String id,
      );

  /// إنشاء مباراة جديدة
  Future<void> create(
      Match match,
      );

  /// تحديث المباراة
  Future<void> update(
      Match match,
      );

  /// حذف المباراة
  Future<void> delete(
      String id,
      );
}