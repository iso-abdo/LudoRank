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



import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';


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
  late final MatchProvider matchProvider;

  @override
  void initState() {
    super.initState();

    matchProvider = sl<MatchProvider>();

    _loadMatches();
  }

  Future<void> _loadMatches() async {
    await matchProvider.loadMatches(
      widget.tournamentId,
    );
  }

  Future<void> _createNewMatch() async {
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
      await _loadMatches();
    }
  }

  Future<void> _refreshMatches() async {
    await _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'مباريات البطولة',
      body: ListenableBuilder(
        listenable: matchProvider,
        builder: (context, _) {
          if (matchProvider.isLoading &&
              matchProvider.matches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (matchProvider.error != null &&
              matchProvider.matches.isEmpty) {
            return _ErrorView(
              message: matchProvider.error!,
              onRetry: _loadMatches,
            );
          }

          final matches = matchProvider.matches;

          if (matches.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshMatches,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),

                  Icon(
                    Icons.sports_esports_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'لا توجد مباريات حتى الآن',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'قم بإنشاء مباراة جديدة واختار اللاعبين المشاركين فيها.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _createNewMatch,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'مباراة جديدة',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshMatches,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MatchesHeader(
                  matchesCount: matches.length,
                  onAddMatch: _createNewMatch,
                ),

                const SizedBox(height: 16),

                ...matches.map(
                      (match) => _MatchCard(
                    match: match,
                    onTap: () {
                      // المرحلة القادمة:
                      // فتح تفاصيل المباراة.
                    },
                  ),
                ),

                if (matchProvider.error != null) ...[
                  const SizedBox(height: 12),

                  Text(
                    matchProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MatchesHeader extends StatelessWidget {
  final int matchesCount;
  final VoidCallback onAddMatch;

  const _MatchesHeader({
    required this.matchesCount,
    required this.onAddMatch,
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
                const Icon(
                  Icons.sports_esports,
                  size: 32,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مباريات البطولة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'عدد المباريات: $matchesCount',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: onAddMatch,
              icon: const Icon(Icons.add),
              label: const Text(
                'مباراة جديدة',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const _MatchCard({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      '#',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مباراة ${match.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'عدد اللاعبين: ${match.playersCount}',
                        ),
                      ],
                    ),
                  ),

                  _MatchStatusChip(
                    status: match.status,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '${match.playersCount} لاعبين',
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchStatusChip extends StatelessWidget {
  final MatchStatus status;

  const _MatchStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _statusText(status),
      ),
    );
  }

  String _statusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return 'معلقة';

      case MatchStatus.playing:
        return 'جارية';

      case MatchStatus.finished:
        return 'منتهية';

      case MatchStatus.cancelled:
        return 'ملغاة';
    }
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),

            const SizedBox(height: 16),

            const Text(
              'حدث خطأ أثناء تحميل المباريات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              label: const Text(
                'إعادة المحاولة',
              ),
            ),
          ],
        ),
      ),
    );
  }
}