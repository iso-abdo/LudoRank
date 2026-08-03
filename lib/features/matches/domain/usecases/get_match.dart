import '../entities/match.dart';
import '../repositories/match_repository.dart';

class GetMatch {
  final MatchRepository repository;

  GetMatch(this.repository);

  Future<Match?> call(String id) {
    return repository.getById(id);
  }
}