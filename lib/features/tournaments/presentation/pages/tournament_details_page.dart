import 'package:flutter/material.dart';
import 'package:ludo_rank/features/matches/presentation/pages/tournament_matches_page.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';
import 'package:ludo_rank/shared/widgets/app_scaffold.dart';
import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/tournament_players/domain/entities/tournament_player.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';

import 'package:ludo_rank/features/tournament_players/presentation/pages/select_players_page.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';

import 'package:uuid/uuid.dart';

import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_standings_provider.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsPage({super.key, required this.tournamentId});

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  final TournamentPlayerProvider tournamentPlayerProvider =
      sl<TournamentPlayerProvider>();
  final TournamentProvider tournamentProvider = sl<TournamentProvider>();
  final PlayerProvider playerProvider = sl<PlayerProvider>();
  final TournamentStandingsProvider standingsProvider =
      sl<TournamentStandingsProvider>();

  final uuid = const Uuid();

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
        builder: (_) => SelectPlayersPage(tournamentId: widget.tournamentId),
      ),
    );

    if (result == null || result.isEmpty) {
      return;
    }

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

    if (mounted) {
      await _loadStandings();
      setState(() {});
    }
  }

  Widget _buildStandingsSection() {
    return ListenableBuilder(
      listenable: standingsProvider,
      builder: (context, _) {
        final snapshot = standingsProvider.snapshot;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ترتيب البطولة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                if (standingsProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (standingsProvider.error != null)
                  Column(
                    children: [
                      const Text('تعذر تحميل ترتيب البطولة'),
                      const SizedBox(height: 8),
                      Text(
                        standingsProvider.error!,
                        textAlign: TextAlign.center,
                      ),
                      TextButton.icon(
                        onPressed: _loadStandings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  )
                else if (snapshot == null)
                  const Text('لا توجد بيانات متاحة للترتيب')
                else ...[
                  Text(
                    'المباريات: ${snapshot.matches.length} '
                    '• المكتملة: ${snapshot.completedMatches}',
                  ),
                  const Divider(height: 24),

                  if (snapshot.completedMatches == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'لسه مفيش مباريات مكتملة. الترتيب هيظهر بعد تسجيل أول نتيجة.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (snapshot.standings.isEmpty)
                    const Text('لا يوجد مشاركون في البطولة')
                  else
                    ...snapshot.standings.map((standing) {
                      final playerName = playerProvider.getPlayerName(
                        standing.playerId,
                      );

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text('${standing.position}'),
                        ),
                        title: Text(playerName),
                        subtitle: Text(
                          'المباريات: ${standing.matchesPlayed}'
                          ' • الفوز: ${standing.wins}'
                          ' • أفضل مركز: '
                          '${standing.bestRank?.toString() ?? "—"}',
                        ),
                        trailing: Text(
                          '${standing.points} نقطة',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "تفاصيل البطولة",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStandingsSection(),
                    const Icon(Icons.emoji_events, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Tournament ID",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(widget.tournamentId, textAlign: TextAlign.center),
                    const Divider(height: 32),
                    const ListTile(
                      leading: Icon(Icons.flag),
                      title: Text("الحالة"),
                      trailing: Chip(label: Text("Draft")),
                    ),
                    AnimatedBuilder(
                      animation: tournamentPlayerProvider,
                      builder: (context, _) {
                        return ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text("اللاعبون"),
                          trailing: Text(
                            "${tournamentPlayerProvider.players.length}",
                          ),
                        );
                      },
                    ),
                    const ListTile(
                      leading: Icon(Icons.sports_esports),
                      title: Text("المباريات"),
                      trailing: Text("0"),
                    ),
                    const ListTile(
                      leading: Icon(Icons.repeat),
                      title: Text("الجولات"),
                      trailing: Text("0"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: tournamentPlayerProvider,
              builder: (context, index) {
                if (tournamentPlayerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tournamentPlayerProvider.players.isEmpty) {
                  return const Center(
                    child: Text("لا يوجد لاعبون داخل البطولة"),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tournamentPlayerProvider.players.length,
                  itemBuilder: (_, index) {
                    final player = tournamentPlayerProvider.players[index];

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        playerProvider.getPlayerName(player.playerId),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addPlayers,
              icon: const Icon(Icons.group_add),
              label: const Text("إضافة لاعبين"),
            ),
            const SizedBox(height: 12),
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
              label: const Text("استكمال البطولة"),
            ),
          ],
        ),
      ),
    );
  }
}
