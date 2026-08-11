/* وظيفتها:

تجيب مباريات البطولة.
تعرض المباريات السابقة.
تعرض حالة كل مباراة.
تحتوي على زر:
+ مباراة جديدة

final MatchProvider matchProvider =
    sl<MatchProvider>();

    @override
void initState() {
  super.initState();

  matchProvider.loadMatches(
    widget.tournamentId,
  );
}


في TournamentDetailsPage:

ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentMatchesPage(
          tournamentId: widget.tournamentId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.play_arrow),
  label: const Text('استكمال البطولة'),
),
*/
import 'package:flutter/material.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/presentation/pages/create_match_page.dart';
import 'package:ludo_rank/features/matches/presentation/providers/match_provider.dart';

import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

class TournamentMatchesPage extends StatefulWidget {
  final String tournamentId;

  const TournamentMatchesPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentMatchesPage> createState() =>
      _TournamentMatchesPageState();
}

class _TournamentMatchesPageState
    extends State<TournamentMatchesPage> {
  final MatchProvider matchProvider =
  sl<MatchProvider>();

  @override
  void initState() {
    super.initState();

    matchProvider.loadMatches(
      widget.tournamentId,
    );
  }

  Future<void> _openCreateMatchPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMatchPage(
          tournamentId: widget.tournamentId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await matchProvider.loadMatches(
        widget.tournamentId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'مباريات البطولة',
      body: ListenableBuilder(
        listenable: matchProvider,
        builder: (context, _) {
          if (matchProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (matchProvider.error != null) {
            return _ErrorView(
              message: matchProvider.error!,
              onRetry: () {
                matchProvider.loadMatches(
                  widget.tournamentId,
                );
              },
            );
          }

          if (matchProvider.matches.isEmpty) {
            return _EmptyMatchesView(
              onCreateMatch: _openCreateMatchPage,
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matchProvider.matches.length,
                  separatorBuilder: (_,_) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final match =
                    matchProvider.matches[index];

                    return _MatchCard(
                      match: match,
                    );
                  },
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateMatchPage,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'مباراة جديدة',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;

  const _MatchCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.sports_esports,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'مباراة',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    match.status.name,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                ),
                const SizedBox(width: 8),
                Text(
                  '${match.playersCount} لاعبين',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.id,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchesView extends StatelessWidget {
  final VoidCallback onCreateMatch;

  const _EmptyMatchesView({
    required this.onCreateMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 20),

            Text(
              'لا توجد مباريات حتى الآن',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'قم بإنشاء أول مباراة واختيار '
                  'اللاعبين المشاركين فيها.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: onCreateMatch,
              icon: const Icon(Icons.add),
              label: const Text(
                'إنشاء أول مباراة',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),

            const SizedBox(height: 16),

            const Text(
              'حدث خطأ أثناء تحميل المباريات',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}