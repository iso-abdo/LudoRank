import 'package:flutter/material.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/matches/presentation/providers/match_provider.dart';
import 'package:ludo_rank/features/matches/presentation/pages/create_match_page.dart';

import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

import 'package:ludo_rank/features/ludo_game/presentation/pages/match_game_page.dart';

import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/match_players/domain/repositories/match_player_repository.dart';

import 'package:ludo_rank/features/players/domain/entities/player.dart';
import 'package:ludo_rank/features/players/domain/repositories/player_repository.dart';

class TournamentMatchesPage extends StatefulWidget {
  final String tournamentId;

  const TournamentMatchesPage({super.key, required this.tournamentId});

  @override
  State<TournamentMatchesPage> createState() => _TournamentMatchesPageState();
}

class _TournamentMatchesPageState extends State<TournamentMatchesPage> {
  late final MatchProvider matchProvider;

  late final MatchPlayerRepository matchPlayerRepository;
  late final PlayerRepository playerRepository;
  String? _expandedMatchId;
  final Map<String, List<_FinishedPlayerResult>> _finishedResults = {};
  final Set<String> _loadingResults = {};
  @override
  void initState() {
    super.initState();

    matchProvider = sl<MatchProvider>();
    matchPlayerRepository = sl<MatchPlayerRepository>();
    playerRepository = sl<PlayerRepository>();

    _loadMatches();
  }

  Future<void> _loadMatches() async {
    await matchProvider.loadMatches(widget.tournamentId);
  }

  Future<void> _createNewMatch() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMatchPage(tournamentId: widget.tournamentId),
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

  Future<void> _toggleFinishedMatch(Match match) async {
    if (_expandedMatchId == match.id) {
      setState(() => _expandedMatchId = null);
      return;
    }

    setState(() => _expandedMatchId = match.id);

    if (_finishedResults.containsKey(match.id) ||
        _loadingResults.contains(match.id)) {
      return;
    }

    setState(() => _loadingResults.add(match.id));

    try {
      final matchPlayers = await matchPlayerRepository.getMatchPlayers(
        match.id,
      );

      final results = await Future.wait(
        matchPlayers.map((matchPlayer) async {
          final player = await playerRepository.getPlayerById(
            matchPlayer.playerId,
          );

          return _FinishedPlayerResult(
            name: player?.name ?? 'لاعب غير معروف',
            seat: matchPlayer.seat,
            rank: matchPlayer.rank,
            points: matchPlayer.points,
            color: _colorForSeat(
              seat: matchPlayer.seat,
              playersCount: match.playersCount,
            ),
          );
        }),
      );

      results.sort((a, b) {
        final rankA = a.rank ?? 999;
        final rankB = b.rank ?? 999;
        return rankA.compareTo(rankB);
      });

      if (!mounted) return;

      setState(() {
        _finishedResults[match.id] = results;
        _loadingResults.remove(match.id);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingResults.remove(match.id));

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('تعذر تحميل نتيجة المباراة: $e')),
        );
    }
  }

  Color _colorForSeat({required int seat, required int playersCount}) {
    // نفس توزيع الألوان المستخدم في المباراة:
    // لاعبان: أخضر، أزرق.
    // 3 أو 4 لاعبين: أخضر، أصفر، أزرق، أحمر.
    if (playersCount == 2) {
      return seat == 1 ? Colors.green : Colors.blue;
    }

    switch (seat) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow.shade700;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openMatch(Match match) async {
    if (match.status != MatchStatus.pending) {
      if (!mounted) {
        return;
      }

      final message = switch (match.status) {
        MatchStatus.playing =>
          'المباراة بدأت بالفعل ولا يمكن استئنافها حاليًا.',
        MatchStatus.finished => 'هذه المباراة منتهية بالفعل.',
        MatchStatus.cancelled => 'هذه المباراة ملغاة.',
        MatchStatus.pending => '',
      };

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

      return;
    }

    try {
      final matchPlayers = await matchPlayerRepository.getMatchPlayers(
        match.id,
      );

      if (!mounted) {
        return;
      }

      final playerEntries = await Future.wait(
        matchPlayers.map((MatchPlayer matchPlayer) async {
          final Player? player = await playerRepository.getPlayerById(
            matchPlayer.playerId,
          );

          if (player == null) {
            throw StateError('اللاعب ${matchPlayer.playerId} غير موجود.');
          }

          return MapEntry(matchPlayer.playerId, player.name);
        }),
      );

      if (!mounted) {
        return;
      }

      final playerNames = <String, String>{
        for (final entry in playerEntries) entry.key: entry.value,
      };

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MatchGamePage(matchId: match.id, playerNames: playerNames),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result == true) {
        await _loadMatches();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('تعذر فتح المباراة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'مباريات البطولة',
      body: ListenableBuilder(
        listenable: matchProvider,
        builder: (context, _) {
          if (matchProvider.isLoading && matchProvider.matches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (matchProvider.error != null && matchProvider.matches.isEmpty) {
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
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'لا توجد مباريات حتى الآن',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    label: const Text('مباراة جديدة'),
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
                    expanded: _expandedMatchId == match.id,
                    loadingResult: _loadingResults.contains(match.id),
                    results: _finishedResults[match.id] ?? const [],
                    onTap: () {
                      if (match.status == MatchStatus.finished) {
                        _toggleFinishedMatch(match);
                      } else {
                        _openMatch(match);
                      }
                    },
                  ),
                ),

                if (matchProvider.error != null) ...[
                  const SizedBox(height: 12),

                  Text(
                    matchProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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

  const _MatchesHeader({required this.matchesCount, required this.onAddMatch});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports, size: 32),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مباريات البطولة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text('عدد المباريات: $matchesCount'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: onAddMatch,
              icon: const Icon(Icons.add),
              label: const Text('مباراة جديدة'),
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
  final bool expanded;
  final bool loadingResult;
  final List<_FinishedPlayerResult> results;

  const _MatchCard({
    required this.match,
    required this.onTap,
    required this.expanded,
    required this.loadingResult,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          '#',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مباراة ${match.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('عدد اللاعبين: ${match.playersCount}'),
                          ],
                        ),
                      ),
                      _MatchStatusChip(status: match.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isFinished ? Icons.emoji_events_outlined : Icons.people,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFinished
                              ? (expanded
                                    ? 'إخفاء نتيجة المباراة'
                                    : 'عرض نتيجة المباراة')
                              : '${match.playersCount} لاعبين',
                        ),
                      ),
                      Icon(
                        isFinished
                            ? (expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down)
                            : Icons.arrow_forward_ios,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildResultContent(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultContent(BuildContext context) {
    final theme = Theme.of(context);

    if (loadingResult) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'لا توجد تفاصيل نتيجة مسجلة لهذه المباراة.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نتيجة المباراة',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        for (final result in results)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: result.color.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: result.color,
                  child: Icon(
                    Icons.person,
                    color: result.color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اللون: ${_colorName(result.color)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result.rank == null
                          ? 'بدون ترتيب'
                          : 'المركز ${result.rank}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('${result.points} نقطة'),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _colorName(Color color) {
    if (color == Colors.green) return 'أخضر';
    if (color == Colors.blue) return 'أزرق';
    if (color == Colors.red) return 'أحمر';
    if (color == Colors.yellow.shade700) return 'أصفر';
    return 'غير محدد';
  }
}

class _MatchStatusChip extends StatelessWidget {
  final MatchStatus status;

  const _MatchStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(_statusText(status)));
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

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60),

            const SizedBox(height: 16),

            const Text(
              'حدث خطأ أثناء تحميل المباريات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(message, textAlign: TextAlign.center),

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

class _FinishedPlayerResult {
  final String name;
  final int seat;
  final int? rank;
  final int points;
  final Color color;

  const _FinishedPlayerResult({
    required this.name,
    required this.seat,
    required this.rank,
    required this.points,
    required this.color,
  });
}
