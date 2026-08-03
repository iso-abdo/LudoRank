import '../entities/match.dart';
import '../repositories/match_repository.dart';

class UpdateMatch {
  final MatchRepository repository;

  UpdateMatch(this.repository);

  Future<void> call(Match match) {
    return repository.update(match);
  }
}