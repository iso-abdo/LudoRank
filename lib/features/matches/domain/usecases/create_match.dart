import '../entities/match.dart';
import '../repositories/match_repository.dart';

class CreateMatch {
  final MatchRepository repository;

  CreateMatch(this.repository);

  Future<void> call(Match match) {
    return repository.create(match);
  }
}