import '../repositories/match_repository.dart';

class DeleteMatch {
  final MatchRepository repository;

  DeleteMatch(this.repository);

  Future<void> call(String id) {
    return repository.delete(id);
  }
}