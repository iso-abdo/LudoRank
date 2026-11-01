
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';
import 'package:ludo_rank/features/matches/presentation/pages/tournament_matches_page.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';
import 'package:ludo_rank/features/tournament_players/presentation/pages/select_players_page.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';
import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_standings_provider.dart';
import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailsPage> createState() =>
      _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  final TournamentPlayerProvider tournamentPlayerProvider =
  sl<TournamentPlayerProvider>();

  final TournamentProvider tournamentProvider =
  sl<TournamentProvider>();

  final PlayerProvider playerProvider =
  sl<PlayerProvider>();

  final TournamentStandingsProvider standingsProvider =
  sl<TournamentStandingsProvider>();

  final uuid = const Uuid();

  bool _participantsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      tournamentPlayerProvider.loadPlayers(widget.tournamentId),
      playerProvider.loadPlayers(),
      tournamentProvider.loadTournament(widget.tournamentId),
    ]);

    if (!mounted) return;

    await _loadStandings();
  }

  Future<void> _loadStandings() async {
    await standingsProvider.load(
      tournamentId: widget.tournamentId,
      participants: List.of(tournamentPlayerProvider.players),
    );
  }

  Future<void> _addPlayers() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectPlayersPage(
          tournamentId: widget.tournamentId,
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    for (final playerId in result) {
      await tournamentPlayerProvider.addPlayer(
        TournamentPlayer(
          id: uuid.v4(),
          tournamentId: widget.tournamentId,
          playerId: playerId,
          joinedAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;

    await _loadStandings();

    if (mounted) {
      setState(() {});
    }
  }

  String _statusLabel(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return 'مسودة';
      case TournamentStatus.ready:
        return 'جاهزة';
      case TournamentStatus.running:
        return 'جارية';
      case TournamentStatus.finished:
        return 'مكتملة';
      case TournamentStatus.cancelled:
        return 'ملغاة';
    }
  }

  Color _statusColor(
      TournamentStatus status,
      ColorScheme colors,
      ) {
    switch (status) {
      case TournamentStatus.draft:
        return colors.outline;
      case TournamentStatus.ready:
        return colors.primary;
      case TournamentStatus.running:
        return Colors.green;
      case TournamentStatus.finished:
        return Colors.amber.shade700;
      case TournamentStatus.cancelled:
        return colors.error;
    }
  }

  Widget _buildHeader() {
    return ListenableBuilder(
      listenable: tournamentProvider,
      builder: (context, _) {
        final tournament = tournamentProvider.currentTournament;
        final colors = Theme.of(context).colorScheme;

        final status = tournament?.status;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.amber.shade700,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament?.name ?? 'تفاصيل البطولة',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'بطولة LudoRank',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status, colors)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status, colors),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (tournamentProvider.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          child: Column(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return ListenableBuilder(
      listenable: tournamentPlayerProvider,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: standingsProvider,
          builder: (context, _) {
            final snapshot = standingsProvider.snapshot;

            final participantCount =
                tournamentPlayerProvider.players.length;

            final totalMatches = snapshot?.matches.length;
            final completedMatches = snapshot?.completedMatches;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'المشاركون',
                  value: '$participantCount',
                  accent: Colors.lightBlue,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  icon: Icons.sports_esports_rounded,
                  label: 'إجمالي المباريات',
                  value: totalMatches?.toString() ?? '—',
                  accent: Colors.deepPurpleAccent,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'مباريات مكتملة',
                  value: completedMatches?.toString() ?? '—',
                  accent: Colors.green,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _addPlayers,
            icon: const Icon(Icons.group_add_rounded, size: 19),
            label: const Text(
              'إضافة لاعبين',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
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
            icon: const Icon(Icons.play_arrow_rounded, size: 21),
            label: const Text(
              'استكمال البطولة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandingsSection() {
    return ListenableBuilder(
      listenable: standingsProvider,
      builder: (context, _) {
        final snapshot = standingsProvider.snapshot;
        final colors = Theme.of(context).colorScheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.leaderboard_rounded,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ترتيب البطولة',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (snapshot != null)
                      Text(
                        '${snapshot.completedMatches} مكتملة',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                if (standingsProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (standingsProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 34,
                        ),
                        const SizedBox(height: 8),
                        const Text('تعذر تحميل ترتيب البطولة'),
                        const SizedBox(height: 4),
                        Text(
                          standingsProvider.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadStandings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                else if (snapshot == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'لا توجد بيانات متاحة للترتيب حاليًا.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (snapshot.completedMatches == 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 38,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'لسه مفيش مباريات مكتملة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'الترتيب هيظهر بعد تسجيل أول نتيجة.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else if (snapshot.standings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'لا يوجد مشاركون في البطولة.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...snapshot.standings.map((standing) {
                          final playerName = playerProvider.getPlayerName(
                            standing.playerId,
                          );

                          final isFirst = standing.position == 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? Colors.amber.withValues(alpha: 0.10)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isFirst
                                  ? Border.all(
                                color: Colors.amber.withValues(alpha: 0.35),
                              )
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isFirst
                                    ? Colors.amber.shade700
                                    : colors.surfaceContainerHighest,
                                foregroundColor: isFirst
                                    ? Colors.black
                                    : colors.onSurface,
                                child: isFirst
                                    ? const Icon(Icons.emoji_events_rounded)
                                    : Text('${standing.position}'),
                              ),
                              title: Text(
                                playerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight:
                                  isFirst ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'المباريات: ${standing.matchesPlayed}'
                                      ' • الفوز: ${standing.wins}'
                                      ' • أفضل مركز: '
                                      '${standing.bestRank?.toString() ?? "—"}',
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${standing.points}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isFirst
                                          ? Colors.amber.shade700
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    'نقطة',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipantsSection() {
    return ListenableBuilder(
      listenable: tournamentPlayerProvider,
      builder: (context, _) {
        final players = tournamentPlayerProvider.players;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ExpansionTile(
                key: PageStorageKey(
                  'tournament-participants-${widget.tournamentId}',
                ),
                initiallyExpanded: _participantsExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _participantsExpanded = expanded;
                  });
                },
                leading: const Icon(Icons.groups_rounded),
                title: Text(
                  'المشاركون (${players.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('اضغط لعرض أسماء اللاعبين'),
                childrenPadding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ),
                children: [
                  if (tournamentPlayerProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else if (players.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لسه مفيش لاعبين في البطولة. استخدم زر إضافة لاعبين.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...players.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 17,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          playerProvider.getPlayerName(player.playerId),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تفاصيل البطولة',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),

            _buildSummaryStats(),
            const SizedBox(height: 12),

            // الأزرار موجودة مباشرة بعد الهيدر والإحصائيات.
            _buildActionButtons(),
            const SizedBox(height: 16),

            _buildStandingsSection(),
            const SizedBox(height: 12),

            _buildParticipantsSection(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
