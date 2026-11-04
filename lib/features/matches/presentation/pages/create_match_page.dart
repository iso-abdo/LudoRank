import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';

import 'package:ludo_rank/features/matches/domain/entities/match.dart';
import 'package:ludo_rank/features/matches/domain/entities/match_status.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';
import 'package:ludo_rank/features/matches/domain/Use-cases/create_match.dart';
import 'package:ludo_rank/features/ludo_game/presentation/pages/match_game_page.dart';
import 'package:ludo_rank/features/tournament_players/presentation/providers/tournament_player_provider.dart';
import 'package:ludo_rank/features/players/presentation/providers/player_provider.dart';
import 'package:ludo_rank/shared/widgets/app_scaffold.dart';

class CreateMatchPage extends StatefulWidget {
  final String tournamentId;

  const CreateMatchPage({super.key, required this.tournamentId});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final TournamentPlayerProvider tournamentPlayerProvider =
      sl<TournamentPlayerProvider>();

  final CreateMatch createMatch = sl<CreateMatch>();
  final PlayerProvider playerProvider = sl<PlayerProvider>();
  final Uuid uuid = const Uuid();

  int? _playersCount;

  final Set<String> _selectedPlayerIds = {};

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();

    tournamentPlayerProvider.loadPlayers(widget.tournamentId);
    playerProvider.loadPlayers();
  }

  void _selectPlayersCount(int count) {
    setState(() {
      _playersCount = count;

      // لو غيرنا عدد اللاعبين،
      // نمسح الاختيارات القديمة حتى لا تصبح غير صالحة.
      _selectedPlayerIds.clear();
    });
  }

  Color _getSeatColor(int seat, int playersCount) {
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

  void _togglePlayer(String playerId) {
    if (_playersCount == null) {
      return;
    }

    setState(() {
      if (_selectedPlayerIds.contains(playerId)) {
        _selectedPlayerIds.remove(playerId);
        return;
      }

      if (_selectedPlayerIds.length >= _playersCount!) {
        return;
      }

      _selectedPlayerIds.add(playerId);
    });
  }

  bool get _canCreateMatch {
    return _playersCount != null &&
        _selectedPlayerIds.length == _playersCount &&
        !_isCreating;
  }

  Future<void> _createNewMatch() async {
    if (!_canCreateMatch) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final now = DateTime.now();

      final match = Match(
        id: uuid.v4(),
        tournamentId: widget.tournamentId,
        playersCount: _playersCount!,
        status: MatchStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final selectedPlayers = _selectedPlayerIds.toList();

      await playerProvider.loadPlayers();

      final playerNames = <String, String>{
        for (final playerId in selectedPlayers)
          playerId: playerProvider.getPlayerName(playerId),
      };

      if (playerNames.values.any((name) => name == 'لاعب غير معروف')) {
        throw StateError('تعذر تحميل أسماء كل اللاعبين المختارين.');
      }
      final matchPlayers = <MatchPlayer>[];

      for (var i = 0; i < selectedPlayers.length; i++) {
        matchPlayers.add(
          MatchPlayer(
            id: uuid.v4(),
            matchId: match.id,
            playerId: selectedPlayers[i],
            seat: i + 1,
            rank: null,
            points: 0,
            finished: false,
          ),
        );
      }

      await createMatch(match: match, players: matchPlayers);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              MatchGamePage(matchId: match.id, playerNames: playerNames),
        ),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل إنشاء المباراة: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إنشاء مباراة',
      body: ListenableBuilder(
        listenable: tournamentPlayerProvider,
        builder: (context, _) {
          if (tournamentPlayerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tournamentPlayerProvider.error != null) {
            return Center(child: Text(tournamentPlayerProvider.error!));
          }

          final players = tournamentPlayerProvider.players;

          if (players.isEmpty) {
            return const Center(child: Text('لا يوجد لاعبين داخل البطولة'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'عدد اللاعبين في المباراة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _PlayersCountButton(
                        count: 2,
                        selected: _playersCount == 2,
                        onTap: () {
                          _selectPlayersCount(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PlayersCountButton(
                        count: 3,
                        selected: _playersCount == 3,
                        onTap: () {
                          _selectPlayersCount(3);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PlayersCountButton(
                        count: 4,
                        selected: _playersCount == 4,
                        onTap: () {
                          _selectPlayersCount(4);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_playersCount == null)
                  const Text(
                    'اختار عدد اللاعبين أولاً',
                    textAlign: TextAlign.center,
                  ),

                if (_playersCount != null) ...[
                  Text(
                    'اختار $_playersCount لاعبين',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...players.map((tournamentPlayer) {
                    final playerId = tournamentPlayer.playerId;

                    final selected = _selectedPlayerIds.contains(playerId);

                    final disabled =
                        !selected &&
                        _selectedPlayerIds.length >= _playersCount!;

                    final seat = selected ? _getSeat(playerId) : 0;

                    final seatColor = selected
                        ? _getSeatColor(seat, _playersCount!)
                        : Theme.of(context).colorScheme.surfaceContainerHighest;

                    final backgroundColor = selected
                        ? seatColor.withValues(alpha: 0.16)
                        : Theme.of(context).colorScheme.surface;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected
                              ? seatColor
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 1.5 : 0.7,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CheckboxListTile(
                        value: selected,
                        onChanged: disabled
                            ? null
                            : (_) {
                                _togglePlayer(playerId);
                              },
                        activeColor: selected ? seatColor : null,
                        secondary: selected
                            ? CircleAvatar(
                                backgroundColor: seatColor,
                                child: Text(
                                  '$seat',
                                  style: TextStyle(
                                    color: seatColor.computeLuminance() > 0.5
                                        ? Colors.black87
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                        title: Text(
                          playerProvider.getPlayerName(playerId),
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          selected ? 'المقعد: $seat' : 'لم يتم اختيار المقعد',
                          style: TextStyle(
                            color: selected ? seatColor : null,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  Text(
                    'تم اختيار ${_selectedPlayerIds.length} '
                    'من $_playersCount',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _canCreateMatch ? _createNewMatch : null,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _isCreating ? 'جاري إنشاء المباراة...' : 'إنشاء المباراة',
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

  int _getSeat(String playerId) {
    final index = _selectedPlayerIds.toList().indexOf(playerId);

    return index == -1 ? 0 : index + 1;
  }
}

class _PlayersCountButton extends StatelessWidget {
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _PlayersCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text('$count لاعبين'),
    );
  }
}
